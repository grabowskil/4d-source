-- FourD Physgun: hält Objekte wie die Physgun; E + Maus dreht in den w-Ebenen.
SWEP.PrintName = "FourD Physgun"
SWEP.Author = "MyPhys"
SWEP.Category = "FourD"
SWEP.Instructions = "Links: greifen · Mausrad: Abstand · E + Maus: 4D-Drehung (Shift: 45°) · R: R4 zurücksetzen"
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
    self:NetworkVar("Float", 0, "DragX")     -- akkumulierte Drag-Winkel (Grad), nur Anzeige
    self:NetworkVar("Float", 1, "DragY")
end

function SWEP:Initialize()
    self:SetHoldType("physgun")
end

function SWEP:SecondaryAttack()
end
