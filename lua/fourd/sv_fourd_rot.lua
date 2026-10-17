-- Serverseitige 4D-Orientierung R4 pro Entity (lokaler Objektrahmen, Welt = Angles · R4).
-- Sync zum Client als NW2String (8 Zahlen in einem Wert, damit L und R atomar ankommen).
FourD = FourD or {}
FourD.Rots = FourD.Rots or {}        -- ent -> r (nur Nicht-Identität); überlebt lua_refresh_file

local M = FourD.Math

-- Liefert eine Kopie von R4. Ungültige oder nicht gedrehte Entities -> Identität.
function FourD.GetRot(ent)
    local r = IsValid(ent) and FourD.Rots[ent]
    if not r then return M.Identity() end
    return M.Copy(r)
end

-- Setzt R4 für ein gültiges Entity. r: 8 endliche Zahlen, |L| und |R| nahe 1.
-- Gibt true bei Erfolg zurück, sonst false.
function FourD.SetRot(ent, r)
    if not IsValid(ent) then return false end
    local new = M.Validate(r)
    if not new then return false end

    local old = FourD.GetRot(ent)
    if M.IsIdentity(new) then
        FourD.Rots[ent] = nil
    else
        FourD.Rots[ent] = new
    end
    ent:SetNW2String(FourD.ROT_NW_KEY, M.Serialize(new))

    hook.Run("FourD_Rotated", ent, old, M.Copy(new))
    return true
end

hook.Add("EntityRemoved", "fourd_rot_cleanup", function(ent)
    FourD.Rots[ent] = nil
end)
