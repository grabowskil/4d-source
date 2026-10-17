return {
    groupName = "FourD",

    beforeEach = function(state)
        local ent = ents.Create("prop_physics")
        ent:SetModel("models/props_junk/PopCan01a.mdl")
        ent:SetPos(Vector(0, 0, 100))
        ent:Spawn()
        state.ent = ent
    end,

    afterEach = function(state)
        hook.Remove("FourD_Changed", "fourd_test_changed")
        if IsValid(state.ent) then state.ent:Remove() end
    end,

    cases = {
        {
            name = "Neues Entity bekommt den Default-Wert für t",
            async = true,
            timeout = 2,
            func = function(state)
                local ent = state.ent
                timer.Simple(0.1, function()
                    expect(FourD.Values[ent]).to.equal(FourD.GetDefault())
                    expect(FourD.Get(ent)).to.equal(FourD.GetDefault())
                    done()
                end)
            end
        },
        {
            name = "Set ändert den Wert und feuert FourD_Changed",
            func = function(state)
                local ent = state.ent
                local seen
                hook.Add("FourD_Changed", "fourd_test_changed", function(e, old, new)
                    if e == ent then seen = { old = old, new = new } end
                end)

                FourD.Set(ent, 1)
                expect(FourD.Set(ent, 42.5)).to.beTrue()

                expect(FourD.Get(ent)).to.equal(42.5)
                expect(ent:GetNW2Float("fourd_t")).to.equal(42.5)
                expect(seen.old).to.equal(1)
                expect(seen.new).to.equal(42.5)
            end
        },
        {
            name = "Set lehnt nil, NaN, inf, String und ungültige Entities ab",
            func = function(state)
                local ent = state.ent
                FourD.Set(ent, 7)

                expect(FourD.Set(ent, nil)).to.beFalse()
                expect(FourD.Set(ent, 0 / 0)).to.beFalse()
                expect(FourD.Set(ent, math.huge)).to.beFalse()
                expect(FourD.Set(ent, -math.huge)).to.beFalse()
                expect(FourD.Set(ent, "5")).to.beFalse()
                expect(FourD.Set(NULL, 1)).to.beFalse()
                expect(FourD.Get(ent)).to.equal(7)
            end
        },
        {
            name = "Nach Remove() ist der Eintrag weg",
            async = true,
            timeout = 2,
            func = function(state)
                local ent = state.ent
                FourD.Set(ent, 3)
                ent:Remove()
                timer.Simple(0.1, function()
                    expect(FourD.Values[ent]).to.beNil()
                    done()
                end)
            end
        },
    }
}
