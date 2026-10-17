local M = FourD.Math
local abs, rad, cos, sin = math.abs, math.rad, math.cos, math.sin

local function maxOffIdentity(m)
    local worst = 0
    for i = 1, 4 do
        for j = 1, 4 do
            local want = (i == j) and 1 or 0
            worst = math.max(worst, abs(m[i][j] - want))
        end
    end
    return worst
end

-- max |M·Mᵀ − I|
local function orthoError(m)
    local p = { {}, {}, {}, {} }
    for i = 1, 4 do
        for j = 1, 4 do
            local s = 0
            for k = 1, 4 do s = s + m[i][k] * m[j][k] end
            p[i][j] = s
        end
    end
    return maxOffIdentity(p)
end

local function maxDiff(a, b)
    local worst = 0
    for i = 1, 4 do
        for j = 1, 4 do
            worst = math.max(worst, abs(a[i][j] - b[i][j]))
        end
    end
    return worst
end

return {
    groupName = "FourD.Math",

    cases = {
        {
            name = "Drehung in xw um θ entspricht x' = x·cosθ − w·sinθ, w' = x·sinθ + w·cosθ",
            func = function()
                local theta = rad(37)
                local r = M.Plane(1, 4, theta)
                local x, y, z, w = 2, -3, 5, 7
                local ox, oy, oz, ow = M.Apply(r, x, y, z, w)

                expect(abs(ox - (x * cos(theta) - w * sin(theta))) < 1e-9).to.beTrue()
                expect(abs(ow - (x * sin(theta) + w * cos(theta))) < 1e-9).to.beTrue()
                expect(abs(oy - y) < 1e-9).to.beTrue()
                expect(abs(oz - z) < 1e-9).to.beTrue()
            end
        },
        {
            name = "Drehung in xy um θ ist die gewöhnliche 3D-Drehung um z, w bleibt",
            func = function()
                local theta = rad(30)
                local ox, oy, oz, ow = M.Apply(M.Plane(1, 2, theta), 1, 0, 4, 9)
                expect(abs(ox - cos(theta)) < 1e-9).to.beTrue()
                expect(abs(oy - sin(theta)) < 1e-9).to.beTrue()
                expect(abs(oz - 4) < 1e-9).to.beTrue()
                expect(abs(ow - 9) < 1e-9).to.beTrue()
            end
        },
        {
            name = "Nach 10 000 kleinen Schritten ist die Orientierung orthonormal",
            func = function()
                local r = M.Identity()
                local a = M.Plane(1, 4, rad(0.37))
                local b = M.Plane(2, 3, rad(0.11))
                local c = M.PlaneW(0.6, 0, 0.8, rad(0.23))
                for _ = 1, 10000 do
                    r = M.Normalize(M.Mul(c, M.Mul(b, M.Mul(a, r))))
                end
                expect(orthoError(M.ToMatrix(r)) < 1e-9).to.beTrue()
            end
        },
        {
            name = "8 × 45° in derselben Ebene ergeben die Identität",
            func = function()
                for _, plane in ipairs({ { 1, 4 }, { 2, 4 }, { 3, 4 }, { 1, 2 } }) do
                    local step = M.Plane(plane[1], plane[2], rad(45))
                    local r = M.Identity()
                    for _ = 1, 8 do r = M.Normalize(M.Mul(step, r)) end
                    expect(maxOffIdentity(M.ToMatrix(r)) < 1e-9).to.beTrue()
                    expect(M.IsIdentity(r)).to.beTrue()
                end
            end
        },
        {
            name = "Drehungen in verschiedenen Ebenen kommutieren im Allgemeinen nicht",
            func = function()
                local a = M.Plane(1, 4, rad(40))
                local b = M.Plane(1, 2, rad(70))
                local ab = M.ToMatrix(M.Mul(a, b))
                local ba = M.ToMatrix(M.Mul(b, a))
                expect(maxDiff(ab, ba) > 0.1).to.beTrue()

                -- Gegenprobe: vollständig orthogonale Ebenen (xy, zw) kommutieren.
                local c = M.Plane(3, 4, rad(25))
                expect(maxDiff(M.ToMatrix(M.Mul(b, c)), M.ToMatrix(M.Mul(c, b))) < 1e-9).to.beTrue()
            end
        },
        {
            name = "PlaneAngles: einfache Drehung hat β = 0, doppelte Drehung beide Winkel",
            func = function()
                local alpha, beta = M.PlaneAngles(M.Plane(1, 4, rad(60)))
                expect(abs(alpha - 60) < 1e-6).to.beTrue()
                expect(abs(beta) < 1e-6).to.beTrue()

                alpha, beta = M.PlaneAngles(M.Mul(M.Plane(1, 2, rad(30)), M.Plane(3, 4, rad(80))))
                expect(abs(alpha - 80) < 1e-6).to.beTrue()
                expect(abs(beta - 30) < 1e-6).to.beTrue()
            end
        },
        {
            name = "Maus-Deltas: Clamp, NaN wird ignoriert, Drag dreht in (rechts, w) und (oben, w)",
            func = function()
                expect(M.AccumulateMouse(0, 10, 0.2, 100)).to.aboutEqual(2)
                expect(M.AccumulateMouse(0, 5000, 0.2, 100)).to.aboutEqual(20)
                expect(M.AccumulateMouse(0, -5000, 0.2, 100)).to.aboutEqual(-20)
                expect(M.AccumulateMouse(3, 0 / 0, 0.2, 100)).to.equal(3)
                expect(M.AccumulateMouse(3, math.huge, 0.2, 100)).to.equal(3)

                -- Blick-rechts = lokales +x, Blick-oben = lokales +z: 30° nach rechts ist Ebene xw.
                local right, up = { 1, 0, 0 }, { 0, 0, 1 }
                local r = M.FromMouseDrag(M.Identity(), right, up, 30, 0, false)
                expect(maxDiff(M.ToMatrix(r), M.ToMatrix(M.Plane(1, 4, rad(30)))) < 1e-9).to.beTrue()

                -- Shift: 30° rastet auf 45° ein, 20° auf 0°.
                r = M.FromMouseDrag(M.Identity(), right, up, 30, 20, true)
                expect(maxDiff(M.ToMatrix(r), M.ToMatrix(M.Plane(1, 4, rad(45)))) < 1e-9).to.beTrue()

                -- Beide Achsen: erst rechts, dann oben, von einem Startwert aus.
                local start = M.Plane(1, 2, rad(10))
                r = M.FromMouseDrag(start, right, up, 15, -25, false)
                local want = M.Mul(M.Plane(3, 4, rad(-25)), M.Mul(M.Plane(1, 4, rad(15)), start))
                expect(maxDiff(M.ToMatrix(r), M.ToMatrix(want)) < 1e-9).to.beTrue()
            end
        },
        {
            name = "Serialize/Deserialize: Rundreise, Identität als leerer String, Müll -> nil",
            func = function()
                local r = M.Mul(M.Plane(1, 4, rad(33)), M.Plane(2, 3, rad(12)))
                local back = M.Deserialize(M.Serialize(r))
                expect(maxDiff(M.ToMatrix(back), M.ToMatrix(r)) < 1e-6).to.beTrue()

                expect(M.Serialize(M.Identity())).to.equal("")
                expect(M.IsIdentity(M.Deserialize(""))).to.beTrue()
                expect(M.Deserialize("1 0 0 0 1 0 0")).to.beNil()
                expect(M.Deserialize("1 0 0 0 1 0 0 nan")).to.beNil()
                expect(M.Deserialize("1 0 0 0 1 0 0 0 0")).to.beNil()
                expect(M.Deserialize("2 0 0 0 1 0 0 0")).to.beNil()
            end
        },
    }
}
