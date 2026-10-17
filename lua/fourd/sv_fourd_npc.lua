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

-- Feuert auch bei der ersten Zuweisung (FourD.Assign), also für jedes neue NPC und jeden Spieler.
hook.Add("FourD_Changed", "fourd_npc_changed", function(ent)
    if not IsValid(ent) or not (ent:IsNPC() or FourD.IsPhaseActor(ent)) then return end
    ent:SetCustomCollisionCheck(true)
    ent:CollisionRulesChanged()
    syncEnt(ent)
end)

hook.Add("EntityTakeDamage", "fourd_npc_damage", function(target, dmg)
    if FourD.NpcBlocksDamage(target, dmg:GetAttacker()) then return true end
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
    local d = FourD.Thickness()
    if d == lastThickness then return end
    lastThickness = d
    for _, ent in ipairs(ents.GetAll()) do
        if ent:IsNPC() or FourD.IsPhaseActor(ent) then ent:CollisionRulesChanged() end
    end
    FourD.NpcSyncAll()
end)
