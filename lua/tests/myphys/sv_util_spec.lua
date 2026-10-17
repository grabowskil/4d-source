return {
    groupName = "MyPhys Util",

    cases = {
        {
            name = "SafeClamp klemmt normale Werte",
            func = function()
                expect(MyPhys.SafeClamp(5000, -3000, 3000)).to.equal(3000)
                expect(MyPhys.SafeClamp(-10, -3000, 3000)).to.equal(-10)
            end
        },
        {
            name = "SafeClamp verwirft NaN, inf und Nicht-Zahlen",
            func = function()
                expect(MyPhys.SafeClamp(0 / 0, -1, 1)).to.beNil()
                expect(MyPhys.SafeClamp(math.huge, -1, 1)).to.beNil()
                expect(MyPhys.SafeClamp(-math.huge, -1, 1)).to.beNil()
                expect(MyPhys.SafeClamp("5", -1, 1)).to.beNil()
            end
        },
        {
            name = "ClampVector kürzt auf maxLen und behält die Richtung",
            func = function()
                local v = MyPhys.ClampVector(Vector(0, 0, 500), 100)
                expect(v.z).to.aboutEqual(100)
                expect(MyPhys.ClampVector(Vector(3, 4, 0), 10):Length()).to.aboutEqual(5)
            end
        },
    }
}
