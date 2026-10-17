-- Physik-Tuner: Masse und Dämpfung einzelner Props einstellen.
TOOL.Category = "MyPhys"
TOOL.Name = "#tool.myphys_tuner.name"

TOOL.ClientConVar["mass"] = "50"
TOOL.ClientConVar["damping"] = "0"

TOOL.Information = {
    { name = "left" },
    { name = "right" },
}

if CLIENT then
    language.Add("tool.myphys_tuner.name", "Physik-Tuner")
    language.Add("tool.myphys_tuner.desc", "Masse und Dämpfung von Props einstellen")
    language.Add("tool.myphys_tuner.left", "Werte anwenden")
    language.Add("tool.myphys_tuner.right", "Werte vom Prop übernehmen")
    language.Add("tool.myphys_tuner.mass", "Masse")
    language.Add("tool.myphys_tuner.damping", "Dämpfung")
end

local function getPhys(trace)
    local ent = trace.Entity
    if not IsValid(ent) or ent:IsPlayer() then return end

    local phys = ent:GetPhysicsObjectNum(trace.PhysicsBone or 0)
    if IsValid(phys) then return phys end
end

function TOOL:LeftClick(trace)
    if not IsValid(trace.Entity) or trace.Entity:IsPlayer() then return false end
    if CLIENT then return true end

    local phys = getPhys(trace)
    if not phys then return false end

    local cfg = MyPhys.Config.Tuner
    local mass = MyPhys.SafeClamp(self:GetClientNumber("mass", 50), cfg.MinMass, cfg.MaxMass)
    local damping = MyPhys.SafeClamp(self:GetClientNumber("damping", 0), 0, cfg.MaxDamping)
    if not mass or not damping then return false end

    phys:SetMass(mass)
    phys:SetDamping(damping, damping)
    phys:Wake()
    return true
end

function TOOL:RightClick(trace)
    if not IsValid(trace.Entity) or trace.Entity:IsPlayer() then return false end
    if CLIENT then return true end

    local phys = getPhys(trace)
    if not phys then return false end

    local linDamp = phys:GetDamping()
    local owner = self:GetOwner()
    owner:ConCommand("myphys_tuner_mass " .. phys:GetMass())
    owner:ConCommand("myphys_tuner_damping " .. linDamp)
    return true
end

function TOOL.BuildCPanel(panel)
    panel:Help("#tool.myphys_tuner.desc")
    panel:NumSlider("#tool.myphys_tuner.mass", "myphys_tuner_mass", 0.1, 50000, 1)
    panel:NumSlider("#tool.myphys_tuner.damping", "myphys_tuner_damping", 0, 100, 2)
end
