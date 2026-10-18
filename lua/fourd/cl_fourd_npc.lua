-- Client: Körper (NPCs samt Waffe, deren Ragdolls) außerhalb der Phase gegenüber dem lokalen
-- Spieler ausblenden, auch bei R4 = Identität. In Phase greift der Schnitt aus cl_fourd_rot.
-- Hält außerdem die clientseitigen Kollisionsregeln für die Bewegungsvorhersage aktuell
-- (ShouldCollide in sh_fourd_npc). Nur Darstellung.
FourD = FourD or {}
FourD.ClNpcHidden = FourD.ClNpcHidden or {}   -- ent -> true, solange wir SetNoDraw gesetzt haben
FourD.ClRagdolls = FourD.ClRagdolls or {}     -- clientseitiges Ragdoll -> { t, r } des NPCs

local cvHide = CreateClientConVar("fourd_cl_npc_hide", "1", true, false,
    "Hide NPCs that are out of phase (0 = off)", 0, 1)

local UPDATE_INTERVAL = 0.1
local lastKey = setmetatable({}, { __mode = "k" })   -- ent -> zuletzt gesehenes "t|R4"
local lastD

local function hide(ent)
    if not FourD.ClNpcHidden[ent] then
        if ent:GetNoDraw() then return end         -- vom Server unsichtbar: nicht anfassen
        FourD.ClNpcHidden[ent] = true
    end
    ent:SetNoDraw(true)                            -- erneut, falls ein Netzupdate es überschrieb
end

local function unhide(ent)
    FourD.ClNpcHidden[ent] = nil
    if IsValid(ent) then ent:SetNoDraw(false) end
end

-- Clientseitige Ragdolls gehören nur uns: ohne GetNoDraw-Vorprüfung (sie können das Flag vom
-- ausgeblendeten NPC erben) und zusätzlich per Null-Matrix, falls SetNoDraw dort nicht greift.
local ZERO = Matrix()
ZERO:Scale(Vector(0, 0, 0))

local function updateRagdoll(rag, info, tMe, d, enabled)
    if enabled and not FourD.InPhaseSlice(info.t, tMe, d, info.r, rag:OBBMins(), rag:OBBMaxs()) then
        rag:SetNoDraw(true)
        rag:EnableMatrix("RenderMultiply", ZERO)
    else
        rag:SetNoDraw(false)
        FourD.ClApplySlice(rag, info.r, info.t)
    end
end

local function updateCollision(ent, force)
    if not ent:GetCustomCollisionCheck() then ent:SetCustomCollisionCheck(true) end
    if FourD.WarmBodyBounds(ent) then force = true end
    local key = FourD.Get(ent) .. "|" .. ent:GetNW2String(FourD.ROT_NW_KEY, "")
    if force or lastKey[ent] ~= key then
        lastKey[ent] = key
        ent:CollisionRulesChanged()
    end
end

local nextUpdate = 0
hook.Add("Think", "fourd_npc_phase", function()
    local now = CurTime()
    if now < nextUpdate then return end
    nextUpdate = now + UPDATE_INTERVAL

    local me = LocalPlayer()
    if not IsValid(me) then return end

    local d = FourD.Thickness()
    local dChanged = d ~= lastD
    lastD = d
    updateCollision(me, dChanged)

    local tMe = FourD.Get(me)
    local enabled = cvHide:GetBool()
    local want = {}
    for _, ent in ipairs(ents.GetAll()) do
        if FourD.IsPhaseBody(ent) then
            updateCollision(ent, dChanged)
            if enabled and not FourD.BodyInPhase(ent, me) then
                want[ent] = true
                local wep = ent:IsNPC() and ent:GetActiveWeapon()
                if IsValid(wep) then want[wep] = true end
            end
        end
    end

    for rag, info in pairs(FourD.ClRagdolls) do
        if IsValid(rag) then
            updateRagdoll(rag, info, tMe, d, enabled)
        else
            FourD.ClRagdolls[rag] = nil
        end
    end

    for ent in pairs(FourD.ClNpcHidden) do
        if not want[ent] then unhide(ent) end
    end
    for ent in pairs(want) do hide(ent) end
end)

-- Clientseitige Ragdolls haben keine NW2-Werte: t und R4 des NPCs beim Tod übernehmen.
hook.Add("CreateClientsideRagdoll", "fourd_npc_cl_ragdoll", function(owner, ragdoll)
    if not IsValid(owner) or not IsValid(ragdoll) or not owner:IsNPC() then return end
    local info = { t = FourD.Get(owner), r = FourD.GetRot(owner) }
    FourD.ClRagdolls[ragdoll] = info
    local me = LocalPlayer()
    if IsValid(me) then                            -- sofort, nicht erst im nächsten Think
        updateRagdoll(ragdoll, info, FourD.Get(me), FourD.Thickness(), cvHide:GetBool())
    end
end)

hook.Add("EntityRemoved", "fourd_npc_cl_cleanup", function(ent)
    FourD.ClNpcHidden[ent] = nil
    FourD.ClRagdolls[ent] = nil
end)
