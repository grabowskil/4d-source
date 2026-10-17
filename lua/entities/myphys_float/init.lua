-- Schwimmkörper mit eigenem Auftrieb per Motion Controller.
-- Ersatz für PhysObj:SetBuoyancyRatio, das auf x86-64/macOS nicht verfügbar ist.
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_junk/wood_crate001a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end

    self:StartMotionController()          -- nach jedem Neuaufbau des PhysObj erneut aufrufen
end

-- Keine EnableCollisions/EnableGravity-Aufrufe in dieser Funktion (Crashgefahr).
-- TODO (ungetestet): Skalierung prüfen – gilt die Kraft pro Tick oder pro Sekunde?
-- Gegenprüfen an Glides sv_wheels.lua (github.com/StyledStrike/gmod-glide).
function ENT:PhysicsSimulate(phys, dt)
    local inWater = bit.band(util.PointContents(phys:GetPos()), MASK_WATER) ~= 0
    if not inWater then return vector_origin, vector_origin, SIM_GLOBAL_FORCE end

    local cfg = MyPhys.Config.Float
    local mass = phys:GetMass()
    local g = -physenv.GetGravity().z

    local lift = Vector(0, 0, mass * g * cfg.Lift)       -- eigener Auftrieb
    local damp = -phys:GetVelocity() * mass * cfg.Drag    -- Wasserwiderstand
    local force = MyPhys.ClampVector(lift + damp, cfg.MaxForce)

    return vector_origin, force * dt, SIM_GLOBAL_FORCE
end
