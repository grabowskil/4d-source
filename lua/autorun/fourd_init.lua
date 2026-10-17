-- Loader (shared). Läuft in beiden Realms; verteilt Client-Dateien und bindet pro Realm ein.
FourD = FourD or {}              -- refresh-sicher: Zustand bleibt beim Neuladen erhalten

if SERVER then
    AddCSLuaFile("fourd/sh_fourd.lua")
    AddCSLuaFile("fourd/sh_fourd_math.lua")
    AddCSLuaFile("fourd/cl_fourd_rot.lua")

    include("fourd/sh_fourd.lua")
    include("fourd/sh_fourd_math.lua")
    include("fourd/sv_fourd.lua")
    include("fourd/sv_fourd_rot.lua")
else
    include("fourd/sh_fourd.lua")
    include("fourd/sh_fourd_math.lua")
    include("fourd/cl_fourd_rot.lua")
end
