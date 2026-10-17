-- Client: R4 aus NW2 lesen und (Annäherung) den 3D-Schnitt per RenderMultiply-Matrix andeuten.
-- Kollision und Physik bleiben unverändert; das hier ist nur Darstellung.
FourD = FourD or {}
FourD.ClTracked = FourD.ClTracked or {}   -- ent -> true, solange R4 nicht die Identität ist

local M = FourD.Math
local abs, sqrt = math.abs, math.sqrt

local cvSlice = CreateClientConVar("fourd_cl_slice", "1", true, false,
    "Schnitt gedrehter Objekte annähernd darstellen (0 = aus)", 0, 1)
local cvThickness = GetConVar("fourd_thickness")

local UPDATE_INTERVAL = 0.1
local cache = setmetatable({}, { __mode = "k" })   -- ent -> { s = string, r = rot }

-- Liefert eine Kopie von R4 (Identität für ungültige oder nicht gedrehte Entities).
function FourD.GetRot(ent)
    if not IsValid(ent) then return M.Identity() end
    local s = ent:GetNW2String(FourD.ROT_NW_KEY, "")
    local c = cache[ent]
    if not c or c.s ~= s then
        c = { s = s, r = M.Deserialize(s) or M.Identity() }
        cache[ent] = c
    end
    return M.Copy(c.r)
end

local function resetMatrix(ent)
    ent:DisableMatrix("RenderMultiply")
end

-- Affine Abbildung entlang n̂, die [lo, hi] auf das Schnittintervall [x0, x1] legt.
-- Näherung: ignoriert die Scherung bei Doppeldrehungen und spiegelt nicht (c4 < 0).
local function sliceMatrix(ent, r)
    local m = M.ToMatrix(r)
    local nx, ny, nz, c4 = m[4][1], m[4][2], m[4][3], m[4][4]
    local s = sqrt(nx * nx + ny * ny + nz * nz)
    if s < 1e-6 then
        nx, ny, nz = 1, 0, 0
    else
        nx, ny, nz = nx / s, ny / s, nz / s
    end

    local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
    local cx, cy, cz = (mins.x + maxs.x) / 2, (mins.y + maxs.y) / 2, (mins.z + maxs.z) / 2
    local ex, ey, ez = (maxs.x - mins.x) / 2, (maxs.y - mins.y) / 2, (maxs.z - mins.z) / 2
    local mid = cx * nx + cy * ny + cz * nz
    local half = abs(ex * nx) + abs(ey * ny) + abs(ez * nz)
    local lo, hi = mid - half, mid + half

    local delta = FourD.Get(ent) - FourD.Get(LocalPlayer())
    local halfD = (cvThickness and cvThickness:GetFloat() or 0) / 2
    local x0, x1 = M.SliceInterval(s, c4, delta, lo, hi, halfD)

    local mat = Matrix()
    if not x0 or hi - lo < 1e-3 then
        mat:Scale(Vector(0, 0, 0))     -- Schnitt leer: nichts zeichnen
        return mat
    end
    if c4 < 0 then x0, x1 = -x1, -x0 end

    local k = (x1 - x0) / (hi - lo)
    local tr = x0 - k * lo
    local n = { nx, ny, nz }
    local rows = {}
    for i = 1, 3 do
        rows[i] = {}
        for j = 1, 3 do
            rows[i][j] = ((i == j) and 1 or 0) + (k - 1) * n[i] * n[j]
        end
        rows[i][4] = n[i] * tr
    end
    rows[4] = { 0, 0, 0, 1 }
    return Matrix(rows)
end

local function update(ent)
    local r = FourD.GetRot(ent)
    if M.IsIdentity(r) or not cvSlice:GetBool() then
        resetMatrix(ent)
        if M.IsIdentity(r) then FourD.ClTracked[ent] = nil end
        return
    end
    ent:EnableMatrix("RenderMultiply", sliceMatrix(ent, r))
end

hook.Add("EntityNetworkedVarChanged", "fourd_rot_track", function(ent, name)
    if name == FourD.ROT_NW_KEY then FourD.ClTracked[ent] = true end
end)

local nextUpdate = 0
hook.Add("Think", "fourd_rot_slice", function()
    local now = CurTime()
    if now < nextUpdate then return end
    nextUpdate = now + UPDATE_INTERVAL

    for ent in pairs(FourD.ClTracked) do
        if IsValid(ent) then update(ent) else FourD.ClTracked[ent] = nil end
    end
end)

hook.Add("EntityRemoved", "fourd_rot_cl_cleanup", function(ent)
    FourD.ClTracked[ent] = nil
end)

-- Erstladen und Refresh: bereits gedrehte Entities aufnehmen.
for _, ent in ipairs(ents.GetAll()) do
    if ent:GetNW2String(FourD.ROT_NW_KEY, "") ~= "" then FourD.ClTracked[ent] = true end
end
