-- Client: NPCs außerhalb der Phase (gegenüber dem lokalen Spieler) samt Waffe ausblenden,
-- auch bei R4 = Identität. Hält außerdem die clientseitigen Kollisionsregeln für die
-- Bewegungsvorhersage aktuell (ShouldCollide in sh_fourd_npc). Nur Darstellung.
FourD = FourD or {}
FourD.ClNpcHidden = FourD.ClNpcHidden or {}   -- ent -> true, solange wir SetNoDraw gesetzt haben

local cvHide = CreateClientConVar("fourd_cl_npc_hide", "1", true, false,
    "NPCs außerhalb der Phase ausblenden (0 = aus)", 0, 1)

local UPDATE_INTERVAL = 0.1
local lastT = setmetatable({}, { __mode = "k" })   -- ent -> zuletzt gesehenes t
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

local function updateCollision(ent, force)
    if not ent:GetCustomCollisionCheck() then ent:SetCustomCollisionCheck(true) end
    local t = FourD.Get(ent)
    if force or lastT[ent] ~= t then
        lastT[ent] = t
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
        if ent:IsNPC() then
            updateCollision(ent, dChanged)
            if enabled and not FourD.InPhase(FourD.Get(ent), tMe, d) then
                want[ent] = true
                local wep = ent:GetActiveWeapon()
                if IsValid(wep) then want[wep] = true end
            end
        end
    end

    for ent in pairs(FourD.ClNpcHidden) do
        if not want[ent] then unhide(ent) end
    end
    for ent in pairs(want) do hide(ent) end
end)

hook.Add("EntityRemoved", "fourd_npc_cl_cleanup", function(ent)
    FourD.ClNpcHidden[ent] = nil
end)
