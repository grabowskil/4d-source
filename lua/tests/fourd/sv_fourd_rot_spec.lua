local M = FourD.Math

return {
    groupName = "FourD.Rot",

    beforeEach = function(state)
        local ent = ents.Create("prop_physics")
        ent:SetModel("models/props_junk/PopCan01a.mdl")
        ent:SetPos(Vector(0, 0, 100))
        ent:Spawn()
        state.ent = ent
    end,

    afterEach = function(state)
        hook.Remove("FourD_Rotated", "fourd_test_rotated")
        if IsValid(state.ent) then state.ent:Remove() end
    end,

    cases = {
        {
            name = "Default ist die Identität",
            func = function(state)
                expect(FourD.Rots[state.ent]).to.beNil()
                expect(M.IsIdentity(FourD.GetRot(state.ent))).to.beTrue()
                expect(state.ent:GetNW2String(FourD.ROT_NW_KEY, "")).to.equal("")
                expect(M.IsIdentity(FourD.GetRot(NULL))).to.beTrue()
            end
        },
        {
            name = "SetRot ändert den Wert und feuert FourD_Rotated",
            func = function(state)
                local ent = state.ent
                local seen
                hook.Add("FourD_Rotated", "fourd_test_rotated", function(e, old, new)
                    if e == ent then seen = { old = old, new = new } end
                end)

                local r = M.Plane(1, 4, math.rad(30))
                expect(FourD.SetRot(ent, r)).to.beTrue()

                local got = M.ToMatrix(FourD.GetRot(ent))
                local want = M.ToMatrix(r)
                for i = 1, 4 do
                    for j = 1, 4 do
                        expect(got[i][j]).to.aboutEqual(want[i][j])
                    end
                end
                expect(seen).toNot.beNil()
                expect(M.IsIdentity(seen.old)).to.beTrue()
                expect(M.IsIdentity(seen.new)).to.beFalse()
                expect(ent:GetNW2String(FourD.ROT_NW_KEY, "")).toNot.equal("")

                -- Zurück auf Identität: Eintrag weg, NW2 leer.
                expect(FourD.SetRot(ent, M.Identity())).to.beTrue()
                expect(FourD.Rots[ent]).to.beNil()
                expect(ent:GetNW2String(FourD.ROT_NW_KEY, "")).to.equal("")
            end
        },
        {
            name = "SetRot lehnt nil, NaN, inf, falsche Typen und ungültige Entities ab",
            func = function(state)
                local ent = state.ent
                local r = M.Plane(2, 4, math.rad(45))
                FourD.SetRot(ent, r)
                local before = FourD.GetRot(ent)

                local nan, inf = 0 / 0, math.huge
                expect(FourD.SetRot(ent, nil)).to.beFalse()
                expect(FourD.SetRot(ent, "1 0 0 0 1 0 0 0")).to.beFalse()
                expect(FourD.SetRot(ent, 1)).to.beFalse()
                expect(FourD.SetRot(ent, { 1, 0, 0, 0, 1, 0, 0 })).to.beFalse()
                expect(FourD.SetRot(ent, { nan, 0, 0, 0, 1, 0, 0, 0 })).to.beFalse()
                expect(FourD.SetRot(ent, { 1, 0, 0, 0, inf, 0, 0, 0 })).to.beFalse()
                expect(FourD.SetRot(ent, { 1, 0, 0, -inf, 1, 0, 0, 0 })).to.beFalse()
                expect(FourD.SetRot(ent, { 1, 0, 0, "0", 1, 0, 0, 0 })).to.beFalse()
                expect(FourD.SetRot(ent, { 2, 0, 0, 0, 1, 0, 0, 0 })).to.beFalse()
                expect(FourD.SetRot(NULL, M.Identity())).to.beFalse()

                local after = FourD.GetRot(ent)
                for i = 1, 8 do expect(after[i]).to.equal(before[i]) end
            end
        },
        {
            name = "Nach Remove() ist der Eintrag weg",
            async = true,
            timeout = 2,
            func = function(state)
                local ent = state.ent
                FourD.SetRot(ent, M.Plane(1, 4, math.rad(90)))
                expect(FourD.Rots[ent]).toNot.beNil()
                ent:Remove()
                timer.Simple(0.1, function()
                    expect(FourD.Rots[ent]).to.beNil()
                    done()
                end)
            end
        },
    }
}
