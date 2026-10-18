-- Phasenregel (rein, beide Realms): zwei Körper sind „in Phase“, wenn sich ihre w-Intervalle
-- [t − d/2, t + d/2] berühren, also |tA − tB| ≤ d/2. Mit R4 ≠ Identität: Schnitt nicht leer.
FourD = FourD or {}

local M = FourD.Math
local abs, floor, sqrt = math.abs, math.floor, math.sqrt

local EPS = 1e-6              -- Toleranz gegen Rundungsfehler aus aufsummierten Schritten
local WHEEL_MAX = 10          -- Clamp der Mausrad-Rasten pro UserCmd
local STEP, STEP_FINE = 0.5, 0.1

-- Obergrenze |t| für die Steuerung der FourD Physgun. Repliziert, damit das HUD sie kennt.
CreateConVar("fourd_max_t", "64", { FCVAR_ARCHIVE, FCVAR_REPLICATED },
    "Maximum absolute t when shifting with the FourD Physgun", 0, 4096)

local function isFinite(v)
    return isnumber(v) and v == v and v ~= math.huge and v ~= -math.huge
end

-- true, wenn |tA − tB| ≤ d/2. Ungültige Eingaben (kein endlicher Wert) -> true, also
-- normales Spielverhalten statt Unverwundbarkeit. d < 0 wird wie 0 behandelt.
function FourD.InPhase(tA, tB, d)
    if not isFinite(tA) or not isFinite(tB) or not isFinite(d) then return true end
    if d < 0 then d = 0 end
    return abs(tA - tB) <= d / 2 + EPS
end

-- Richtung n̂ der w-Neigung von R4 (s = |n|, c4 = R4[4][4]) und Ausdehnung [lo, hi] der
-- Box mins/maxs entlang n̂. Ohne Neigung (s ≈ 0) gilt n̂ = x.
function FourD.SliceAxis(r, mins, maxs)
    local m = M.ToMatrix(r)
    local nx, ny, nz, c4 = m[4][1], m[4][2], m[4][3], m[4][4]
    local s = sqrt(nx * nx + ny * ny + nz * nz)
    if s < 1e-6 then
        nx, ny, nz = 1, 0, 0
    else
        nx, ny, nz = nx / s, ny / s, nz / s
    end

    local cx, cy, cz = (mins.x + maxs.x) / 2, (mins.y + maxs.y) / 2, (mins.z + maxs.z) / 2
    local ex, ey, ez = (maxs.x - mins.x) / 2, (maxs.y - mins.y) / 2, (maxs.z - mins.z) / 2
    local mid = cx * nx + cy * ny + cz * nz
    local half = abs(ex * nx) + abs(ey * ny) + abs(ez * nz)
    return s, c4, nx, ny, nz, mid - half, mid + half
end

-- In Phase mit R4: Der Schnitt des Körpers (Box × [−d/2, d/2], gedreht mit r) mit dem 3D-Raum
-- des Betrachters ist nicht leer (wie die Darstellung in cl_fourd_rot). r = nil oder Identität
-- -> FourD.InPhase. Ungültige Zahlen -> true.
function FourD.InPhaseSlice(tBody, tViewer, d, r, mins, maxs)
    if not r or M.IsIdentity(r) then return FourD.InPhase(tBody, tViewer, d) end
    if not isFinite(tBody) or not isFinite(tViewer) or not isFinite(d) then return true end
    if d < 0 then d = 0 end

    local s, c4, _, _, _, lo, hi = FourD.SliceAxis(r, mins, maxs)
    if hi - lo < 1e-3 then return false end
    return M.SliceInterval(s, c4, tBody - tViewer, lo, hi, d / 2 + EPS) ~= nil
end

-- Neuer t-Wert nach `wheel` Mausrad-Rasten (±0,5 je Raste, fein ±0,1), geclampt auf ±maxT
-- und auf 1e-3 gerundet. Gibt nil zurück, wenn t oder wheel nicht endlich sind.
function FourD.WheelStepT(t, wheel, fine, maxT)
    if not isFinite(t) or not isFinite(wheel) then return nil end
    if not isFinite(maxT) or maxT < 0 then maxT = 0 end

    wheel = math.Clamp(wheel, -WHEEL_MAX, WHEEL_MAX)
    local v = t + wheel * (fine and STEP_FINE or STEP)
    v = floor(v * 1000 + 0.5) / 1000
    return math.Clamp(v, -maxT, maxT)
end
