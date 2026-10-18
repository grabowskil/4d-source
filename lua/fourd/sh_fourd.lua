-- Gemeinsame API (beide Realms). Der Wert t wird per NW2 vom Server zum Client gespiegelt.
FourD = FourD or {}

FourD.NW_KEY = "fourd_t"
FourD.ROT_NW_KEY = "fourd_r"      -- R4 als String (siehe FourD.Math.Serialize)

-- Dicke d jedes Objekts in w (Körper = 3D-Modell × [−d/2, d/2]). Repliziert, nur Darstellung.
CreateConVar("fourd_thickness", "2", { FCVAR_ARCHIVE, FCVAR_REPLICATED },
    "Thickness of objects in the 4th dimension (units)", 0, 4096)

-- Liefert die 4. Koordinate t eines Entities. Server: aus der Tracking-Tabelle,
-- Client: aus der NW2-Variable. Ungültige oder (noch) nicht zugewiesene Entities -> 0.
function FourD.Get(ent)
    if not IsValid(ent) then return 0 end

    if SERVER and FourD.Values then
        local t = FourD.Values[ent]
        if t ~= nil then return t end
    end

    return ent:GetNW2Float(FourD.NW_KEY, 0)
end
