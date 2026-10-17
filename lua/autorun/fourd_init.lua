-- Loader (shared). Läuft in beiden Realms; verteilt Client-Dateien und bindet pro Realm ein.
FourD = FourD or {}              -- refresh-sicher: Zustand bleibt beim Neuladen erhalten

if SERVER then
    AddCSLuaFile("fourd/sh_fourd.lua")

    include("fourd/sh_fourd.lua")
    include("fourd/sv_fourd.lua")
else
    include("fourd/sh_fourd.lua")
end
