-- FourD Physgun: hält Objekte wie die Physgun; E + Maus dreht in den w-Ebenen.
SWEP.PrintName = "FourD Physgun"
SWEP.Author = "MyPhys"
SWEP.Category = "FourD"
SWEP.Instructions = "Left: grab · Mouse wheel: distance · E + mouse: 4D rotation (Shift: 45°) · R: reset R4\n"
    .. "Hold right: select target · + mouse wheel: t ±0.5 (Shift ±0.1) · + R: t = own t · + E + mouse: rotate"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Base = "weapon_base"

SWEP.ViewModel = "models/weapons/c_superphyscannon.mdl"
SWEP.WorldModel = "models/weapons/w_physics.mdl"
SWEP.UseHands = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

function SWEP:SetupDataTables()
    self:NetworkVar("Entity", 0, "HeldEnt")
    self:NetworkVar("Entity", 1, "ShiftEnt")  -- per Rechtsklick gewähltes Ziel (t verschieben)
    self:NetworkVar("Float", 0, "DragX")     -- akkumulierte Drag-Winkel (Grad), nur Anzeige
    self:NetworkVar("Float", 1, "DragY")
end

-- Nach lua_refresh fehlen bei schon existierenden Waffen neue NetworkVar-Accessoren
-- (SetupDataTables läuft nur beim Erzeugen). Bis zum Neuausrüsten dann ohne Shift-Ziel.
function SWEP:GetShiftTarget()
    return self.GetShiftEnt and self:GetShiftEnt() or NULL
end

function SWEP:Initialize()
    self:SetHoldType("physgun")
end

function SWEP:SecondaryAttack()
end
