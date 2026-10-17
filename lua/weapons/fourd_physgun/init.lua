AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local M = FourD.Math

FourD.PhysgunHeld = FourD.PhysgunHeld or {}   -- ent -> Waffe; ein Prop nur von einer FourD Physgun

local RANGE = 4096
local MIN_DIST, MAX_DIST = 32, 4096
local WHEEL_STEP = 24
local SENS = 0.2              -- Grad pro Maus-Einheit
local MAX_MOUSE = 200         -- Clamp pro UserCmd
local SHADOW = {              -- Shadow-Control-Grenzen (geclampte Kräfte)
    secondstoarrive = 0.05,
    maxspeed = 1500, maxspeeddamp = 10000,
    maxangular = 720, maxangulardamp = 10000,
    dampfactor = 0.8, teleportdistance = 0,
}

local function isFiniteVector(v)
    return M.IsFinite(v.x) and M.IsFinite(v.y) and M.IsFinite(v.z)
end

-- Richtung (Welt) in den Rahmen der 3D-Angles des Objekts, normiert.
local function dirToLocal(dir, ang)
    local v = WorldToLocal(dir, angle_zero, vector_origin, ang)
    v:Normalize()
    return { v.x, v.y, v.z }
end

function SWEP:CanGrab(ent)
    local owner = self:GetOwner()
    if not IsValid(ent) or ent:IsWorld() or ent:IsPlayer() then return false end
    if ent:GetMoveType() ~= MOVETYPE_VPHYSICS then return false end
    local phys = ent:GetPhysicsObject()
    if not IsValid(phys) then return false end
    if IsValid(FourD.PhysgunHeld[ent]) then return false end
    return hook.Run("PhysgunPickup", owner, ent) ~= false
end

function SWEP:PrimaryAttack()
    if IsValid(self:GetHeldEnt()) then return end
    local owner = self:GetOwner()
    if not IsValid(owner) or not owner:IsPlayer() then return end

    local tr = util.TraceLine({
        start = owner:EyePos(),
        endpos = owner:EyePos() + owner:GetAimVector() * RANGE,
        filter = owner,
    })
    local ent = tr.Entity
    if not self:CanGrab(ent) then return end

    local phys = ent:GetPhysicsObject()
    local eyeYaw = Angle(0, owner:EyeAngles().y, 0)
    self.fourd = {
        dist = math.Clamp(tr.HitPos:Distance(owner:EyePos()), MIN_DIST, MAX_DIST),
        offset = WorldToLocal(tr.HitPos, angle_zero, phys:GetPos(), phys:GetAngles()),
        relAng = select(2, WorldToLocal(vector_origin, phys:GetAngles(), vector_origin, eyeYaw)),
    }
    -- Eingefrorene Props nur kurzzeitig auftauen; beim Loslassen wieder einfrieren.
    self.fourd.wasFrozen = not phys:IsMotionEnabled()
    phys:EnableMotion(true)
    phys:Wake()
    FourD.PhysgunHeld[ent] = self
    self:SetHeldEnt(ent)
    hook.Run("OnPhysgunPickup", owner, ent)
    self:SetDragX(0)
    self:SetDragY(0)
end

function SWEP:Release()
    local ent, st = self:GetHeldEnt(), self.fourd
    if IsValid(ent) then
        FourD.PhysgunHeld[ent] = nil
        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then
            if st and st.wasFrozen then phys:EnableMotion(false) end
            phys:Wake()
        end
        local owner = self:GetOwner()
        if st and IsValid(owner) then hook.Run("PhysgunDrop", owner, ent) end
    end
    self.fourd = nil
    self:SetHeldEnt(NULL)
end

function SWEP:Think()
    local ent = self:GetHeldEnt()
    if not IsValid(ent) then
        if self.fourd then self:Release() end
        return
    end

    local owner = self:GetOwner()
    local phys = ent:GetPhysicsObject()
    local st = self.fourd
    if not st or not IsValid(owner) or not owner:Alive() or not owner:KeyDown(IN_ATTACK)
        or not IsValid(phys) then
        self:Release()
        return
    end

    local eyeYaw = Angle(0, owner:EyeAngles().y, 0)
    local _, ang = LocalToWorld(vector_origin, st.relAng, vector_origin, eyeYaw)
    local grab = owner:EyePos() + owner:GetAimVector() * st.dist
    local pos = grab - LocalToWorld(st.offset, angle_zero, vector_origin, ang)
    if not isFiniteVector(pos) then return end

    phys:Wake()
    local params = table.Copy(SHADOW)
    params.pos = pos
    params.angle = ang
    params.deltatime = FrameTime()
    phys:ComputeShadowControl(params)
end

function SWEP:Reload()
    local ent = self:GetHeldEnt()
    if IsValid(ent) and not M.IsIdentity(FourD.GetRot(ent)) then
        FourD.SetRot(ent, M.Identity())
    end
end

function SWEP:Holster()
    self:Release()
    return true
end

function SWEP:OnDrop()
    self:Release()
end

function SWEP:OnRemove()
    self:Release()
end

-- Eingabe serverautoritativ aus dem UserCmd: Mausrad = Abstand, E + Maus = 4D-Drehung.
function SWEP:HandleCommand(cmd)
    local ent, st = self:GetHeldEnt(), self.fourd
    if not IsValid(ent) or not st then return end

    local wheel = cmd:GetMouseWheel()
    if M.IsFinite(wheel) and wheel ~= 0 then
        st.dist = math.Clamp(st.dist + math.Clamp(wheel, -10, 10) * WHEEL_STEP, MIN_DIST, MAX_DIST)
    end

    if not cmd:KeyDown(IN_USE) then
        st.drag = nil
        return
    end

    local drag = st.drag
    if not drag then
        local eye, ang = self:GetOwner():EyeAngles(), ent:GetAngles()
        drag = {
            start = FourD.GetRot(ent),
            right = dirToLocal(eye:Right(), ang),
            up = dirToLocal(eye:Up(), ang),
            ax = 0, ay = 0, lastX = 0, lastY = 0,
        }
        st.drag = drag
    end

    drag.ax = M.AccumulateMouse(drag.ax, cmd:GetMouseX(), SENS, MAX_MOUSE)
    drag.ay = M.AccumulateMouse(drag.ay, -cmd:GetMouseY(), SENS, MAX_MOUSE)
    local snap = cmd:KeyDown(IN_SPEED)
    local ax = snap and M.Snap(drag.ax, 45) or drag.ax
    local ay = snap and M.Snap(drag.ay, 45) or drag.ay
    if ax == drag.lastX and ay == drag.lastY then return end
    drag.lastX, drag.lastY = ax, ay

    local r = M.FromMouseDrag(drag.start, drag.right, drag.up, ax, ay, false)
    if r then FourD.SetRot(ent, r) end
    self:SetDragX(ax)
    self:SetDragY(ay)
end

hook.Add("StartCommand", "fourd_physgun_input", function(ply, cmd)
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and wep:GetClass() == "fourd_physgun" then
        wep:HandleCommand(cmd)
    end
end)

-- Solange gehalten wird, löst E kein +use aus (sonst hebt der Spieler das Prop in die Hände).
hook.Add("PlayerUse", "fourd_physgun_nouse", function(ply)
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and wep:GetClass() == "fourd_physgun" and IsValid(wep:GetHeldEnt()) then
        return false
    end
end)

hook.Add("EntityRemoved", "fourd_physgun_cleanup", function(ent)
    FourD.PhysgunHeld[ent] = nil
end)
