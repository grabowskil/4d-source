AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local M = FourD.Math

FourD.PhysgunHeld = FourD.PhysgunHeld or {}   -- ent -> Waffe; ein Prop nur von einer FourD Physgun

local RANGE = 4096
local MIN_DIST, MAX_DIST = 32, 4096
local WHEEL_STEP = 24
local SHIFT_WHEEL_INTERVAL = 0.05   -- höchstens ein t-Schritt pro Intervall (FourD.Set ist teuer)
local SHIFT_PICK_INTERVAL = 0.1     -- Zielwahl-Versuche, solange Rechtsklick ohne Ziel gehalten
local SENS = 0.2              -- Grad pro Maus-Einheit
local MAX_MOUSE = 200         -- Clamp pro UserCmd
local cvMaxT = GetConVar("fourd_max_t")
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

-- Ziel für Rechtsklick-Shift: alles außer Welt und Spielern, sofern die Physgun es greifen dürfte
-- (Sandbox-Hook PhysgunPickup, gilt auch für NPCs; Prop-Protection hängt sich dort ein).
function SWEP:CanShift(ent)
    if not IsValid(ent) or ent:IsWorld() or ent:IsPlayer() then return false end
    return hook.Run("PhysgunPickup", self:GetOwner(), ent) ~= false
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
    -- R gehört bei Rechtsklick dem t-Reset (HandleShift), bis R losgelassen wird.
    if self.fourdShift or self.fourdReloadBlock then return end
    local ent = self:GetHeldEnt()
    if IsValid(ent) and not M.IsIdentity(FourD.GetRot(ent)) then
        FourD.SetRot(ent, M.Identity())
    end
end

function SWEP:EndShift()
    self.fourdShift = nil
    if IsValid(self:GetShiftTarget()) then self:SetShiftEnt(NULL) end
end

function SWEP:Holster()
    self:Release()
    self:EndShift()
    return true
end

function SWEP:OnDrop()
    self:Release()
    self:EndShift()
end

function SWEP:OnRemove()
    self:Release()
    self:EndShift()
end

-- E + Maus dreht R4 von ent. Zustand in state.drag, Winkel ab dem Drücken von E akkumuliert.
function SWEP:DragRotate(ent, state, cmd)
    if not cmd:KeyDown(IN_USE) then
        state.drag = nil
        return
    end

    local drag = state.drag
    if not drag then
        local eye, ang = self:GetOwner():EyeAngles(), ent:GetAngles()
        drag = {
            start = FourD.GetRot(ent),
            right = dirToLocal(eye:Right(), ang),
            up = dirToLocal(eye:Up(), ang),
            ax = 0, ay = 0, lastX = 0, lastY = 0,
        }
        state.drag = drag
        self:SetDragX(0)
        self:SetDragY(0)
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

-- Rechtsklick gehalten: Ziel wählen (gehaltenes Prop oder Fadenkreuz), dann Mausrad = t,
-- R = t auf das eigene t, E + Maus = R4 drehen.
function SWEP:HandleShift(cmd)
    if not self.SetShiftEnt then return end      -- vor dem Refresh erzeugt (siehe GetShiftTarget)
    local owner = self:GetOwner()
    local sh = self.fourdShift
    if not sh then
        local now = CurTime()
        if now < (self.fourdNextPick or 0) then return end
        self.fourdNextPick = now + SHIFT_PICK_INTERVAL
        local ent = self:GetHeldEnt()
        if not IsValid(ent) then
            ent = util.TraceLine({
                start = owner:EyePos(),
                endpos = owner:EyePos() + owner:GetAimVector() * RANGE,
                filter = owner,
            }).Entity
        end
        if not self:CanShift(ent) then return end   -- weiter zielen, solange gehalten
        sh = { ent = ent, reloadHeld = cmd:KeyDown(IN_RELOAD) }
        self.fourdShift = sh
        self:SetShiftEnt(ent)
    end

    local ent = sh.ent
    if not IsValid(ent) then
        self:EndShift()
        return
    end

    local reload = cmd:KeyDown(IN_RELOAD)
    if reload and not sh.reloadHeld then FourD.Set(ent, FourD.Get(owner)) end
    sh.reloadHeld = reload

    local wheel = cmd:GetMouseWheel()
    if wheel ~= 0 and CurTime() >= (sh.nextWheel or 0) then
        sh.nextWheel = CurTime() + SHIFT_WHEEL_INTERVAL
        local cur = FourD.Get(ent)
        local t = FourD.WheelStepT(cur, wheel, cmd:KeyDown(IN_SPEED), cvMaxT and cvMaxT:GetFloat() or 0)
        if t and t ~= cur then FourD.Set(ent, t) end
    end

    self:DragRotate(ent, sh, cmd)
end

-- Eingabe serverautoritativ aus dem UserCmd: Rechtsklick = Shift-Modus (hat Vorrang),
-- sonst beim Halten Mausrad = Abstand, E + Maus = 4D-Drehung.
function SWEP:HandleCommand(cmd)
    if not cmd:KeyDown(IN_RELOAD) then
        self.fourdReloadBlock = nil
    elseif cmd:KeyDown(IN_ATTACK2) then
        self.fourdReloadBlock = true
    end

    if cmd:KeyDown(IN_ATTACK2) then
        if self.fourd then self.fourd.drag = nil end   -- Halte-Drag nicht mit altem Start fortsetzen
        self:HandleShift(cmd)
        return
    end
    if self.fourdShift then self:EndShift() end

    local ent, st = self:GetHeldEnt(), self.fourd
    if not IsValid(ent) or not st then return end

    local wheel = cmd:GetMouseWheel()
    if M.IsFinite(wheel) and wheel ~= 0 then
        st.dist = math.Clamp(st.dist + math.Clamp(wheel, -10, 10) * WHEEL_STEP, MIN_DIST, MAX_DIST)
    end

    self:DragRotate(ent, st, cmd)
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
    if IsValid(wep) and wep:GetClass() == "fourd_physgun"
        and (IsValid(wep:GetHeldEnt()) or IsValid(wep:GetShiftTarget())) then
        return false
    end
end)

hook.Add("EntityRemoved", "fourd_physgun_cleanup", function(ent)
    FourD.PhysgunHeld[ent] = nil
end)
