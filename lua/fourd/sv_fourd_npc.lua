-- Serverseitig: NPC und Spieler außerhalb der Phase fügen sich keinen Schaden zu, kollidieren
-- nicht und der NPC behandelt den Spieler als neutral. Die Originalbeziehung wird gespeichert
-- und beim Zurückkommen in Phase wiederhergestellt.
FourD = FourD or {}
FourD.NpcRel = FourD.NpcRel or {}    -- npc -> { [other] = { disp, prio } }; überlebt lua_refresh_file

local OVERRIDE_PRIO = 99

-- Alle Phasen-Akteure (Tests ersetzen das zusammen mit FourD.IsPhaseActor).
function FourD.PhaseActors()
    return player.GetAll()
end

local function restore(npc, other)
    local saved = FourD.NpcRel[npc]
    local orig = saved and saved[other]
    if not orig then return end

    saved[other] = nil
    if next(saved) == nil then FourD.NpcRel[npc] = nil end
    npc:AddEntityRelationship(other, orig[1], orig[2])
end

local function suppress(npc, other)
    local saved = FourD.NpcRel[npc]
    if not saved then
        saved = {}
        FourD.NpcRel[npc] = saved
    end
    if not saved[other] then             -- nur das erste Mal: sonst würde D_NU als Original gelten
        local disp, prio = npc:Disposition(other)
        saved[other] = { disp or D_NU, prio or 0 }
    end

    npc:AddEntityRelationship(other, D_NU, OVERRIDE_PRIO)
    if npc:GetEnemy() == other then npc:SetEnemy(NULL, false) end
    npc:ClearEnemyMemory(other)
end

-- Gleicht die Beziehung npc -> other an die aktuelle Phase an.
function FourD.NpcApplyPair(npc, other)
    if not IsValid(npc) or not npc:IsNPC() or not FourD.IsPhasedPair(npc, other) then return end
    if FourD.EntsInPhase(npc, other) then
        restore(npc, other)
    else
        suppress(npc, other)
    end
end

local function forEachNpc(fn)
    for _, ent in ipairs(ents.GetAll()) do
        if ent:IsNPC() then fn(ent) end
    end
end

local function syncEnt(ent)
    if ent:IsNPC() then
        for _, actor in ipairs(FourD.PhaseActors()) do FourD.NpcApplyPair(ent, actor) end
    end
    if FourD.IsPhaseActor(ent) then
        forEachNpc(function(npc) FourD.NpcApplyPair(npc, ent) end)
    end
end

function FourD.NpcSyncAll()
    forEachNpc(function(npc)
        for _, actor in ipairs(FourD.PhaseActors()) do FourD.NpcApplyPair(npc, actor) end
    end)
end

-- true, wenn Schaden zwischen target und attacker wegen unterschiedlicher Phase entfällt.
function FourD.NpcBlocksDamage(target, attacker)
    return FourD.IsPhasedPair(target, attacker) and not FourD.EntsInPhase(target, attacker)
end

-- Verursacher, der mit target ein Phasen-Paar bildet: Angreifer, Inflictor oder deren Owner
-- (Granaten, Raketen und Waffen tragen NPC bzw. Spieler oft nur als Owner). Sonst nil.
function FourD.DamageSource(target, dmg)
    local attacker, inflictor = dmg:GetAttacker(), dmg:GetInflictor()
    local candidates = {
        attacker, inflictor,
        IsValid(attacker) and attacker:GetOwner() or NULL,
        IsValid(inflictor) and inflictor:GetOwner() or NULL,
    }
    for _, ent in ipairs(candidates) do
        if FourD.IsPhasedPair(target, ent) then return ent end
    end
end

local function onPhaseChange(ent)
    if not IsValid(ent) or not (FourD.IsPhaseBody(ent) or FourD.IsPhaseActor(ent)) then return end
    FourD.WarmBodyBounds(ent)
    ent:SetCustomCollisionCheck(true)
    ent:CollisionRulesChanged()
    syncEnt(ent)
end

-- Feuert auch bei der ersten Zuweisung (FourD.Assign), also für jedes neue Entity. Dabei erbt
-- ein Entity mit Owner (Waffe, Granate, Rakete) dessen t, damit Projektile in dessen Phase bleiben.
hook.Add("FourD_Changed", "fourd_npc_changed", function(ent, old)
    if old == nil and IsValid(ent) then
        local owner = ent:GetOwner()
        if IsValid(owner) and FourD.Get(owner) ~= FourD.Get(ent) then
            FourD.Set(ent, FourD.Get(owner))    -- feuert erneut, dann mit old ~= nil
            return
        end
    end
    onPhaseChange(ent)
end)

-- R4 zählt nur beim Körper (der Betrachter wird als ungedreht behandelt).
hook.Add("FourD_Rotated", "fourd_npc_rotated", function(ent)
    if IsValid(ent) and FourD.IsPhaseBody(ent) then onPhaseChange(ent) end
end)

hook.Add("EntityTakeDamage", "fourd_npc_damage", function(target, dmg)
    local src = FourD.DamageSource(target, dmg)
    if src and FourD.NpcBlocksDamage(target, src) then return true end
end)

-- Server-Ragdolls bleiben in der Phase des NPCs (t, R4) und verhalten sich wie dieser.
hook.Add("CreateEntityRagdoll", "fourd_npc_ragdoll", function(owner, ragdoll)
    if not IsValid(owner) or not IsValid(ragdoll) or not owner:IsNPC() then return end
    ragdoll:SetNW2Bool(FourD.BODY_NW_KEY, true)
    FourD.Set(ragdoll, FourD.Get(owner))
    local r = FourD.GetRot(owner)
    if not FourD.Math.IsIdentity(r) then FourD.SetRot(ragdoll, r) end
end)

hook.Add("EntityRemoved", "fourd_npc_cleanup", function(ent)
    FourD.NpcRel[ent] = nil
    for npc, saved in pairs(FourD.NpcRel) do
        saved[ent] = nil
        if next(saved) == nil then FourD.NpcRel[npc] = nil end
    end
end)

-- Neue Dicke ändert, wer in Phase ist: Kollisionsregeln und Beziehungen neu bewerten.
-- Abfrage statt cvars.AddChangeCallback, weil dessen Callbacks laut Wiki nicht in jedem Fall feuern.
local lastThickness = FourD.Thickness()
timer.Create("fourd_npc_thickness", 1, 0, function()
    -- Hitbox-Box nachholen, wo sie beim ersten Versuch fehlte (Bones direkt nach dem Spawn).
    forEachNpc(function(npc)
        if FourD.WarmBodyBounds(npc) then onPhaseChange(npc) end
    end)

    local d = FourD.Thickness()
    if d == lastThickness then return end
    lastThickness = d
    for _, ent in ipairs(ents.GetAll()) do
        if FourD.IsPhaseBody(ent) or FourD.IsPhaseActor(ent) then ent:CollisionRulesChanged() end
    end
    FourD.NpcSyncAll()
end)
