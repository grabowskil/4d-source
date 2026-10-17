local M = FourD.Math
local nan, inf = 0 / 0, math.huge
local BOX_MIN, BOX_MAX = Vector(-16, -16, 0), Vector(16, 16, 72)

return {
    groupName = "FourD.Phase",

    cases = {
        {
            name = "Grenze genau bei d/2 zählt als in Phase, symmetrisch",
            func = function()
                expect(FourD.InPhase(1, 0, 2)).to.beTrue()
                expect(FourD.InPhase(0, 1, 2)).to.beTrue()
                expect(FourD.InPhase(-1, 0, 2)).to.beTrue()
                expect(FourD.InPhase(1.001, 0, 2)).to.beFalse()
                expect(FourD.InPhase(0, -1.001, 2)).to.beFalse()
                expect(FourD.InPhase(10, 7.5, 5)).to.beTrue()
            end
        },
        {
            name = "Aufsummierte 0,1-Schritte landen nicht knapp außerhalb",
            func = function()
                local t = 0
                for _ = 1, 10 do t = t + 0.1 end
                expect(FourD.InPhase(t, 0, 2)).to.beTrue()
            end
        },
        {
            name = "d = 0 heißt nur gleiches t; negatives d wie 0",
            func = function()
                expect(FourD.InPhase(3, 3, 0)).to.beTrue()
                expect(FourD.InPhase(3, 3.01, 0)).to.beFalse()
                expect(FourD.InPhase(3, 3, -2)).to.beTrue()
                expect(FourD.InPhase(3, 3.5, -2)).to.beFalse()
            end
        },
        {
            name = "NaN, inf und falsche Typen fallen auf normales Verhalten (in Phase) zurück",
            func = function()
                expect(FourD.InPhase(nan, 0, 2)).to.beTrue()
                expect(FourD.InPhase(0, nan, 2)).to.beTrue()
                expect(FourD.InPhase(inf, 0, 2)).to.beTrue()
                expect(FourD.InPhase(0, -inf, 2)).to.beTrue()
                expect(FourD.InPhase(0, 50, nan)).to.beTrue()
                expect(FourD.InPhase(0, 50, inf)).to.beTrue()
                expect(FourD.InPhase("0", 50, 2)).to.beTrue()
                expect(FourD.InPhase(nil, 50, 2)).to.beTrue()
            end
        },
        {
            name = "InPhaseSlice: Identität bzw. nil wie InPhase",
            func = function()
                expect(FourD.InPhaseSlice(1, 0, 2, nil, BOX_MIN, BOX_MAX)).to.beTrue()
                expect(FourD.InPhaseSlice(1.5, 0, 2, nil, BOX_MIN, BOX_MAX)).to.beFalse()
                expect(FourD.InPhaseSlice(1.5, 0, 2, M.Identity(), BOX_MIN, BOX_MAX)).to.beFalse()
            end
        },
        {
            name = "InPhaseSlice: 90° in xw macht die x-Ausdehnung zur w-Ausdehnung",
            func = function()
                local r = M.Plane(1, 4, math.rad(90))
                expect(FourD.InPhaseSlice(10, 0, 2, r, BOX_MIN, BOX_MAX)).to.beTrue()
                expect(FourD.InPhaseSlice(-16, 0, 2, r, BOX_MIN, BOX_MAX)).to.beTrue()
                expect(FourD.InPhaseSlice(20, 0, 2, r, BOX_MIN, BOX_MAX)).to.beFalse()
                -- 45°: Ausdehnung in w = (32·sin + 2·cos)/2 ≈ 12,0
                local r45 = M.Plane(1, 4, math.rad(45))
                expect(FourD.InPhaseSlice(11.5, 0, 2, r45, BOX_MIN, BOX_MAX)).to.beTrue()
                expect(FourD.InPhaseSlice(12.5, 0, 2, r45, BOX_MIN, BOX_MAX)).to.beFalse()
            end
        },
        {
            name = "InPhaseSlice: leere Box nie, ungültige Zahlen immer in Phase",
            func = function()
                local r = M.Plane(1, 4, math.rad(90))
                local p = Vector(1, 2, 3)
                expect(FourD.InPhaseSlice(0, 0, 2, r, p, p)).to.beFalse()
                expect(FourD.InPhaseSlice(nan, 0, 2, r, BOX_MIN, BOX_MAX)).to.beTrue()
                expect(FourD.InPhaseSlice(0, inf, 2, r, BOX_MIN, BOX_MAX)).to.beTrue()
                expect(FourD.InPhaseSlice(50, 0, nan, r, BOX_MIN, BOX_MAX)).to.beTrue()
            end
        },
        {
            name = "WheelStepT: 0,5 pro Raste, fein 0,1, Clamp auf ±maxT",
            func = function()
                expect(FourD.WheelStepT(0, 1, false, 64)).to.equal(0.5)
                expect(FourD.WheelStepT(0, -3, false, 64)).to.equal(-1.5)
                expect(FourD.WheelStepT(0, 1, true, 64)).to.equal(0.1)
                expect(FourD.WheelStepT(0.3, -3, true, 64)).to.equal(0)
                expect(FourD.WheelStepT(63.8, 1, false, 64)).to.equal(64)
                expect(FourD.WheelStepT(-63.8, -2, false, 64)).to.equal(-64)
                expect(FourD.WheelStepT(100, 0, false, 64)).to.equal(64)
                expect(FourD.WheelStepT(0, 100, false, 64)).to.equal(5)   -- Rasten auf ±10 geclampt
            end
        },
        {
            name = "WheelStepT: zehn feine Schritte ergeben exakt 1",
            func = function()
                local t = 0
                for _ = 1, 10 do t = FourD.WheelStepT(t, 1, true, 64) end
                expect(t).to.equal(1)
            end
        },
        {
            name = "WheelStepT verwirft NaN/inf und behandelt ungültiges maxT als 0",
            func = function()
                expect(FourD.WheelStepT(nan, 1, false, 64)).to.beNil()
                expect(FourD.WheelStepT(inf, 1, false, 64)).to.beNil()
                expect(FourD.WheelStepT(0, nan, false, 64)).to.beNil()
                expect(FourD.WheelStepT(0, -inf, false, 64)).to.beNil()
                expect(FourD.WheelStepT(0, 1, false, nan)).to.equal(0)
                expect(FourD.WheelStepT(0, 1, false, -5)).to.equal(0)
            end
        },
    }
}
