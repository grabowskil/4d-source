include("shared.lua")

local M = FourD.Math

SWEP.Slot = 0
SWEP.SlotPos = 5
SWEP.DrawAmmo = false

-- Blick einfrieren, solange E gedrückt und ein Objekt gehalten wird (wie die Physgun).
function SWEP:FreezeMovement()
    local owner = self:GetOwner()
    return IsValid(self:GetHeldEnt()) and IsValid(owner) and owner:KeyDown(IN_USE)
end

-- Debug-Overlay: nur sichtbar, solange diese Waffe aktiv ist.
function SWEP:DrawHUD()
    local ent = self:GetHeldEnt()
    if not IsValid(ent) then
        local tr = LocalPlayer():GetEyeTrace()
        ent = tr.Entity
    end
    if not IsValid(ent) or ent:IsWorld() then return end

    local r = FourD.GetRot(ent)
    local m = M.ToMatrix(r)
    local alpha, beta = M.PlaneAngles(r)
    local tilt = math.deg(math.acos(math.Clamp(m[4][4], -1, 1)))

    local lines = {
        string.format("FourD  %s #%d", ent:GetClass(), ent:EntIndex()),
        string.format("t = %.2f   (Betrachter %.2f)", FourD.Get(ent), FourD.Get(LocalPlayer())),
        string.format("R4: alpha %.1f°  beta %.1f°  w-Neigung %.1f°", alpha, beta, tilt),
        string.format("Drag: rechts-w %.1f°  oben-w %.1f°", self:GetDragX(), self:GetDragY()),
        string.format("w-Zeile: %.3f %.3f %.3f %.3f", m[4][1], m[4][2], m[4][3], m[4][4]),
    }
    local x, y = ScrW() * 0.5 + 40, ScrH() * 0.5 + 40
    for i, text in ipairs(lines) do
        draw.SimpleText(text, "DermaDefault", x, y + (i - 1) * 14, color_white)
    end
end

-- Mausrad ändert beim Halten den Abstand (über CUserCmd:GetMouseWheel) statt die Waffe zu wechseln.
hook.Add("PlayerBindPress", "fourd_physgun_wheel", function(ply, bind, pressed)
    if not pressed then return end
    if bind ~= "invnext" and bind ~= "invprev" then return end
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and wep:GetClass() == "fourd_physgun" and IsValid(wep:GetHeldEnt()) then
        return true
    end
end)
