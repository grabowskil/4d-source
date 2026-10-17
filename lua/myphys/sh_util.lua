-- Kleine, reine Hilfsfunktionen (shared). Ohne Engine-Zustand, daher gut testbar.
MyPhys = MyPhys or {}

local huge = math.huge

-- Gibt nil für Nicht-Zahlen, NaN und ±inf zurück, sonst den geklemmten Wert.
function MyPhys.SafeClamp(x, lo, hi)
    if not isnumber(x) or x ~= x or x == huge or x == -huge then return nil end
    return math.Clamp(x, lo, hi)
end

-- Kürzt einen Vektor auf maxLen, Richtung bleibt erhalten.
function MyPhys.ClampVector(v, maxLen)
    local len = v:Length()
    if len > maxLen then
        return v * (maxLen / len)
    end
    return v
end
