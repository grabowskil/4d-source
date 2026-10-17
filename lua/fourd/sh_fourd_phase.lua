-- Phasenregel (rein, beide Realms): zwei Körper sind „in Phase“, wenn sich ihre w-Intervalle
-- [t − d/2, t + d/2] berühren, also |tA − tB| ≤ d/2. R4 bleibt für das Gameplay unberücksichtigt.
FourD = FourD or {}

local abs, floor = math.abs, math.floor

local EPS = 1e-6              -- Toleranz gegen Rundungsfehler aus aufsummierten Schritten
local WHEEL_MAX = 10          -- Clamp der Mausrad-Rasten pro UserCmd
local STEP, STEP_FINE = 0.5, 0.1

-- Obergrenze |t| für die Steuerung der FourD Physgun. Repliziert, damit das HUD sie kennt.
CreateConVar("fourd_max_t", "64", { FCVAR_ARCHIVE, FCVAR_REPLICATED },
    "Maximaler Betrag von t beim Verschieben per FourD Physgun", 0, 4096)

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
