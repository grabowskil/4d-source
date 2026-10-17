-- Erkennt optionale serverseitige Physik-Backends. Der Lua-Kern funktioniert immer;
-- HolyLib/Volt schalten sich nur zu, wenn der Serverbetreiber sie installiert hat.
local ok = util.IsBinaryModuleInstalled and util.IsBinaryModuleInstalled("holylib")
if ok then ok = pcall(require, "holylib") end

MyPhys.Backend = ok and "holylib" or "lua"

-- Volt (VPhysics-Jolt) registriert eigene ConVars, belegt ab Release 0.20
MyPhys.Volt = ConVarExists("vjolt_constraint_velocity_substeps")

print(string.format("[MyPhys] Physik-Backend: %s | VPhysics: %s",
    MyPhys.Backend, MyPhys.Volt and "Jolt" or "Standard"))
