-- Anzeige und Eingabe, nur Client.
local cvHud = CreateClientConVar("myphys_hud", "1", true, false, "MyPhys-Overlay anzeigen")

hook.Add("HUDPaint", "myphys_hud", function()
    if not cvHud:GetBool() then return end

    local z = GetGlobal2Float("myphys_gravity_z", MyPhys.Config.Gravity.Default)
    draw.SimpleText(string.format("MyPhys | g_z = %.0f", z), "DermaDefault", 16, 16, color_white)
end)

-- myphys_gravity <z>: schickt den Wunsch an den Server, der prüft Rechte und Grenzen
concommand.Add("myphys_gravity", function(_, _, args)
    local z = tonumber(args[1])
    if not z then
        print("Usage: myphys_gravity <z>   (z. B. -600)")
        return
    end

    net.Start(MyPhys.Net.SetGravity)
    net.WriteFloat(z)
    net.SendToServer()
end)
