-- Ohne verbundene Spieler dient ein npc_combine_s als Spieler-Ersatz: FourD.IsPhaseActor und
-- FourD.PhaseActors werden pro Fall ersetzt und in afterEach wiederhergestellt.

local M = FourD.Math

local function spawn(class, pos)
    local ent = ents.Create(class)
    ent:SetPos(pos)
    ent:Spawn()
    return ent
end

local function damage(target, attacker, amount)
    local dmg = DamageInfo()
    dmg:SetDamage(amount)
    dmg:SetDamageType(DMG_GENERIC)
    dmg:SetAttacker(attacker)
    dmg:SetInflictor(attacker)
    return dmg
end

local function noEntryFor(ent)
    for _, saved in pairs(FourD.NpcRel) do
        if saved[ent] ~= nil then return false end
    end
    return true
end

return {
    groupName = "FourD.Npc",

    beforeEach = function(state)
        state.npc = spawn("npc_citizen", Vector(0, 0, 100))
        state.sub = spawn("npc_combine_s", Vector(300, 0, 100))

        state.isActor, state.actors = FourD.IsPhaseActor, FourD.PhaseActors
        FourD.IsPhaseActor = function(ent) return ent == state.sub or state.isActor(ent) end
        FourD.PhaseActors = function()
            local list = { state.sub }
            for _, ply in ipairs(state.actors()) do list[#list + 1] = ply end
            return list
        end

        state.orig = state.npc:Disposition(state.sub)
        FourD.Set(state.npc, 0)
        FourD.Set(state.sub, 0)
    end,

    afterEach = function(state)
        FourD.IsPhaseActor, FourD.PhaseActors = state.isActor, state.actors
        if IsValid(state.prop) then state.prop:Remove() end
        if IsValid(state.npc) then state.npc:Remove() end
        if IsValid(state.sub) then state.sub:Remove() end
    end,

    cases = {
        {
            name = "Default: in Phase, Beziehung unverändert, Schaden möglich",
            func = function(state)
                local npc, sub = state.npc, state.sub
                expect(state.orig).toNot.equal(D_NU)
                expect(FourD.EntsInPhase(npc, sub)).to.beTrue()
                expect(FourD.NpcRel[npc]).to.beNil()
                expect(npc:Disposition(sub)).to.equal(state.orig)
                expect(FourD.NpcBlocksDamage(npc, sub)).to.beFalse()
                expect(npc:GetCustomCollisionCheck()).to.beTrue()

                local hp = npc:Health()
                npc:TakeDamageInfo(damage(npc, sub, 5))
                expect(npc:Health() < hp).to.beTrue()   -- Kontrolle: Schadensweg funktioniert
            end
        },
        {
            name = "Außerhalb der Phase: neutral, kein Schaden in beide Richtungen, keine Kollision",
            func = function(state)
                local npc, sub = state.npc, state.sub
                expect(FourD.Set(npc, 10)).to.beTrue()
                expect(FourD.EntsInPhase(npc, sub)).to.beFalse()
                expect(npc:Disposition(sub)).to.equal(D_NU)
                expect(npc:GetEnemy() == sub).to.beFalse()

                expect(hook.Run("EntityTakeDamage", npc, damage(npc, sub, 5))).to.beTrue()
                expect(hook.Run("EntityTakeDamage", sub, damage(sub, npc, 5))).to.beTrue()
                expect(hook.Run("ShouldCollide", npc, sub)).to.beFalse()
                expect(hook.Run("ShouldCollide", sub, npc)).to.beFalse()

                local hpNpc, hpSub = npc:Health(), sub:Health()
                npc:TakeDamageInfo(damage(npc, sub, 5))
                sub:TakeDamageInfo(damage(sub, npc, 5))
                expect(npc:Health()).to.equal(hpNpc)
                expect(sub:Health()).to.equal(hpSub)
            end
        },
        {
            name = "Zurück in Phase stellt die Originalbeziehung wieder her (auch nach mehreren Shifts)",
            func = function(state)
                local npc, sub = state.npc, state.sub
                FourD.Set(npc, 10)
                FourD.Set(npc, 20)                  -- weiterhin außerhalb: Original nicht überschreiben
                expect(npc:Disposition(sub)).to.equal(D_NU)
                FourD.Set(npc, 0.5)                 -- |Δt| = 0,5 ≤ d/2
                expect(npc:Disposition(sub)).to.equal(state.orig)
                expect(FourD.NpcRel[npc]).to.beNil()
                expect(hook.Run("ShouldCollide", npc, sub)).toNot.equal(false)

                -- Auch wenn sich der Spieler-Ersatz verschiebt.
                FourD.Set(sub, -5)
                expect(npc:Disposition(sub)).to.equal(D_NU)
                FourD.Set(sub, 0)
                expect(npc:Disposition(sub)).to.equal(state.orig)
            end
        },
        {
            name = "Gedreht entscheidet der Schnitt: 90° in xw holt Δt = 5 in Phase",
            func = function(state)
                local npc, sub = state.npc, state.sub
                FourD.Set(npc, 5)
                expect(npc:Disposition(sub)).to.equal(D_NU)
                expect(FourD.SetRot(npc, M.Plane(1, 4, math.rad(90)))).to.beTrue()
                expect(FourD.EntsInPhase(npc, sub)).to.beTrue()
                expect(npc:Disposition(sub)).to.equal(state.orig)
                expect(FourD.SetRot(npc, M.Identity())).to.beTrue()
                expect(npc:Disposition(sub)).to.equal(D_NU)
            end
        },
        {
            name = "Schaden über Owner des Inflictors (Projektil) wird zugeordnet und blockiert",
            func = function(state)
                local npc, sub = state.npc, state.sub
                local prop = ents.Create("prop_physics")
                prop:SetModel("models/props_junk/PopCan01a.mdl")
                prop:SetPos(Vector(0, 300, 100))
                prop:SetOwner(sub)
                prop:Spawn()
                state.prop = prop

                FourD.Set(npc, 10)
                local dmg = damage(npc, prop, 5)
                expect(FourD.DamageSource(npc, dmg)).to.equal(sub)
                expect(hook.Run("EntityTakeDamage", npc, dmg)).to.beTrue()
            end
        },
        {
            name = "Neues Entity mit Owner erbt dessen t",
            async = true,
            timeout = 2,
            func = function(state)
                FourD.Set(state.npc, 10)
                local prop = ents.Create("prop_physics")
                prop:SetModel("models/props_junk/PopCan01a.mdl")
                prop:SetPos(Vector(0, -300, 100))
                prop:SetOwner(state.npc)
                prop:Spawn()
                state.prop = prop
                timer.Simple(0.2, function()
                    expect(FourD.Get(prop)).to.equal(10)
                    done()
                end)
            end
        },
        {
            name = "Nach Remove() des NPCs sind alle Einträge weg",
            async = true,
            timeout = 2,
            func = function(state)
                local npc = state.npc
                FourD.Set(npc, 10)
                expect(FourD.NpcRel[npc]).toNot.beNil()
                npc:Remove()
                timer.Simple(0.1, function()
                    expect(FourD.NpcRel[npc]).to.beNil()
                    done()
                end)
            end
        },
        {
            name = "Nach Remove() des Spieler-Ersatzes sind alle Einträge weg",
            async = true,
            timeout = 2,
            func = function(state)
                local npc, sub = state.npc, state.sub
                FourD.Set(npc, 10)
                expect(noEntryFor(sub)).to.beFalse()
                sub:Remove()
                timer.Simple(0.1, function()
                    expect(noEntryFor(sub)).to.beTrue()   -- Einträge für echte Spieler dürfen bleiben
                    done()
                end)
            end
        },
    }
}
