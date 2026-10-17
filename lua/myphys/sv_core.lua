-- Physik-Logik, nur Server.
util.AddNetworkString(MyPhys.Net.SetGravity)

local cfg = MyPhys.Config

function MyPhys.SetGravityZ(z)
    physenv.SetGravity(Vector(0, 0, z))   -- wirkt auf Physikobjekte, NICHT auf Spieler
    SetGlobal2Float("myphys_gravity_z", z)
end

-- Rate-Limit pro Spieler; wird beim Refresh bewusst zurückgesetzt
local nextAllowed = {}

net.Receive(MyPhys.Net.SetGravity, function(_, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end  -- Client-Input nie trauen

    local now = CurTime()
    if (nextAllowed[ply] or 0) > now then return end
    nextAllowed[ply] = now + cfg.NetCooldown

    local z = MyPhys.SafeClamp(net.ReadFloat(), cfg.Gravity.Min, cfg.Gravity.Max)
    if not z then return end

    MyPhys.SetGravityZ(z)
end)

hook.Add("PlayerDisconnected", "myphys_ratelimit_cleanup", function(ply)
    nextAllowed[ply] = nil
end)

hook.Add("InitPostEntity", "myphys_publish_gravity", function()
    SetGlobal2Float("myphys_gravity_z", physenv.GetGravity().z)
end)
