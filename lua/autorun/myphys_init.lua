-- Loader (shared). Läuft in beiden Realms; verteilt Client-Dateien und bindet pro Realm ein.
MyPhys = MyPhys or {}            -- refresh-sicher: Zustand bleibt beim Neuladen erhalten

if SERVER then
    AddCSLuaFile("myphys/sh_config.lua")
    AddCSLuaFile("myphys/sh_util.lua")
    AddCSLuaFile("myphys/cl_hud.lua")

    include("myphys/sh_config.lua")
    include("myphys/sh_util.lua")
    include("myphys/sv_backend.lua")
    include("myphys/sv_core.lua")
else
    include("myphys/sh_config.lua")
    include("myphys/sh_util.lua")
    include("myphys/cl_hud.lua")
end
