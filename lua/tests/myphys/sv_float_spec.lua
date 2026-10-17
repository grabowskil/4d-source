return {
    groupName = "MyPhys Float",

    afterEach = function(state)
        if IsValid(state.ent) then state.ent:Remove() end
    end,

    cases = {
        {
            name = "Schwimmkörper spawnt mit gültigem PhysObj",
            func = function(state)
                local ent = ents.Create("myphys_float")
                state.ent = ent
                ent:Spawn()

                expect(ent).to.beValid()
                expect(ent:GetPhysicsObject()).to.beValid()
            end
        },
        {
            name = "Außerhalb von Wasser wirkt keine Zusatzkraft",
            func = function(state)
                local ent = ents.Create("myphys_float")
                state.ent = ent
                ent:SetPos(Vector(0, 0, 10000))   -- (Ableitung) auf gm_construct trocken; Map-abhängig
                ent:Spawn()

                local _, lin = ent:PhysicsSimulate(ent:GetPhysicsObject(), FrameTime())
                expect(lin:IsZero()).to.beTrue()
            end
        },
    }
}
