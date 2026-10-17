-- Reine 4D-Mathematik (beide Realms, ohne Entity-Bezug).
-- Eine Drehung r ist ein Paar Einheitsquaternionen (L, R) als flaches Array mit 8 Zahlen
-- { Lw, Lx, Ly, Lz, Rw, Rx, Ry, Rz }. Ein 4D-Vektor (x, y, z, w) wird als Quaternion
-- w + x·i + y·j + z·k gelesen und abgebildet als v' = L · v · conj(R).
-- (L, R) und (-L, -R) sind dieselbe Drehung; Normalize wählt kanonisch Lw >= 0.
FourD = FourD or {}
FourD.Math = FourD.Math or {}

local M = FourD.Math
local cos, sin, sqrt, abs = math.cos, math.sin, math.sqrt, math.abs
local rad, deg, acos = math.rad, math.deg, math.acos

local NORM_TOLERANCE = 1e-3     -- Validate: zulässige Abweichung von |L| = |R| = 1

local function isFinite(v)
    return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end
M.IsFinite = isFinite

-- Quaternionprodukt a·b, Komponenten (w, x, y, z).
local function qmul(aw, ax, ay, az, bw, bx, by, bz)
    return aw * bw - ax * bx - ay * by - az * bz,
           aw * bx + ax * bw + ay * bz - az * by,
           aw * by - ax * bz + ay * bw + az * bx,
           aw * bz + ax * by - ay * bx + az * bw
end

function M.Identity()
    return { 1, 0, 0, 0, 1, 0, 0, 0 }
end

function M.Copy(r)
    return { r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8] }
end

-- Komposition: erst b, dann a anwenden (wie Matrixprodukt A·B).
function M.Mul(a, b)
    local lw, lx, ly, lz = qmul(a[1], a[2], a[3], a[4], b[1], b[2], b[3], b[4])
    local rw, rx, ry, rz = qmul(a[5], a[6], a[7], a[8], b[5], b[6], b[7], b[8])
    return { lw, lx, ly, lz, rw, rx, ry, rz }
end

function M.Inverse(r)
    return { r[1], -r[2], -r[3], -r[4], r[5], -r[6], -r[7], -r[8] }
end

-- Normiert L und R einzeln und wählt das Vorzeichen kanonisch. nil, wenn nicht normierbar.
function M.Normalize(r)
    local nl = sqrt(r[1] * r[1] + r[2] * r[2] + r[3] * r[3] + r[4] * r[4])
    local nr = sqrt(r[5] * r[5] + r[6] * r[6] + r[7] * r[7] + r[8] * r[8])
    if not isFinite(nl) or not isFinite(nr) or nl < 1e-9 or nr < 1e-9 then return nil end

    local sl, sr = 1 / nl, 1 / nr
    if r[1] < 0 then sl, sr = -sl, -sr end
    return { r[1] * sl, r[2] * sl, r[3] * sl, r[4] * sl,
             r[5] * sr, r[6] * sr, r[7] * sr, r[8] * sr }
end

-- Prüft einen Wert von außen: Tabelle mit 8 endlichen Zahlen, |L| und |R| nahe 1.
-- Gibt die normierte Kopie zurück oder nil.
function M.Validate(r)
    if type(r) ~= "table" then return nil end
    for i = 1, 8 do
        if not isFinite(r[i]) then return nil end
    end
    local nl = r[1] * r[1] + r[2] * r[2] + r[3] * r[3] + r[4] * r[4]
    local nr = r[5] * r[5] + r[6] * r[6] + r[7] * r[7] + r[8] * r[8]
    if abs(nl - 1) > NORM_TOLERANCE or abs(nr - 1) > NORM_TOLERANCE then return nil end
    return M.Normalize(r)
end

function M.IsIdentity(r, eps)
    eps = eps or 1e-6
    local m = M.ToMatrix(r)
    for i = 1, 4 do
        for j = 1, 4 do
            local want = (i == j) and 1 or 0
            if abs(m[i][j] - want) > eps then return false end
        end
    end
    return true
end

function M.Apply(r, x, y, z, w)
    local tw, tx, ty, tz = qmul(r[1], r[2], r[3], r[4], w, x, y, z)
    local ow, ox, oy, oz = qmul(tw, tx, ty, tz, r[5], -r[6], -r[7], -r[8])
    return ox, oy, oz, ow
end

-- 4×4-Matrix (Zeilen, m[i][j]): Spalte j ist das Bild des Basisvektors e_j, Reihenfolge x, y, z, w.
function M.ToMatrix(r)
    local m = { {}, {}, {}, {} }
    for j = 1, 4 do
        local e = { 0, 0, 0, 0 }
        e[j] = 1
        local x, y, z, w = M.Apply(r, e[1], e[2], e[3], e[4])
        m[1][j], m[2][j], m[3][j], m[4][j] = x, y, z, w
    end
    return m
end

-- Drehung um theta (Radiant) in der Ebene (u, w); u ist ein 3D-Einheitsvektor im xyz-Raum.
-- u dreht in Richtung w: u -> cos·u + sin·w, w -> -sin·u + cos·w.
function M.PlaneW(ux, uy, uz, theta)
    local c, s = cos(theta / 2), sin(theta / 2)
    return { c, -ux * s, -uy * s, -uz * s, c, ux * s, uy * s, uz * s }
end

-- Einfache Drehung um theta (Radiant) in der Koordinatenebene (a, b), Achsen 1..4 = x, y, z, w.
-- Achse a dreht in Richtung b, z. B. Plane(1, 4, θ): x' = x·cosθ − w·sinθ, w' = x·sinθ + w·cosθ.
function M.Plane(a, b, theta)
    if a == b then return M.Identity() end
    if b == 4 then
        local u = { 0, 0, 0 }
        u[a] = 1
        return M.PlaneW(u[1], u[2], u[3], theta)
    end
    if a == 4 then return M.Plane(b, a, -theta) end

    -- 3D-Ebene: Drehachse c = e_a × e_b, gewöhnliche Quaternion-Rotation q·v·conj(q).
    local c = { 0, 0, 0 }
    local k = 6 - a - b
    c[k] = ((b - a) % 3 == 1) and 1 or -1
    local co, s = cos(theta / 2), sin(theta / 2)
    return { co, c[1] * s, c[2] * s, c[3] * s, co, c[1] * s, c[2] * s, c[3] * s }
end

-- Winkel der doppelten Drehung (alpha >= beta, Grad) aus der isoklinen Zerlegung:
-- |Lw| = cos((α+β)/2), |Rw| = cos((α−β)/2). Einfache Drehung: beta = 0.
function M.PlaneAngles(r)
    local gl = acos(math.min(1, abs(r[1])))
    local gr = acos(math.min(1, abs(r[5])))
    return deg(gl + gr), deg(abs(gl - gr))
end

-- Maus -> Winkel. acc ist ein Akkumulator in Grad, delta die rohe Maus-Bewegung eines
-- UserCmds. Pro Command wird delta auf ±maxDelta begrenzt, nicht endliche Werte zählen als 0.
function M.AccumulateMouse(acc, delta, sens, maxDelta)
    if not isFinite(delta) then delta = 0 end
    if delta > maxDelta then delta = maxDelta elseif delta < -maxDelta then delta = -maxDelta end
    local out = acc + delta * sens
    if not isFinite(out) then return acc end
    return out
end

function M.Snap(angle, step)
    return math.floor(angle / step + 0.5) * step
end

-- Winkel (Grad) eines Drags -> neue Orientierung. rStart: R4 beim Drücken von E.
-- right/up: Blick-rechts und Blick-oben im Rahmen der 3D-Angles des Objekts ({x, y, z}).
-- Weltdrehung G in Ebene (e, w) konjugiert: A⁻¹·G·A ist die Drehung in Ebene (A⁻¹e, w),
-- daher R4' = G_up(ay) · G_right(ax) · rStart. snap: Winkel auf Vielfache von 45° runden.
function M.FromMouseDrag(rStart, right, up, ax, ay, snap)
    if snap then
        ax, ay = M.Snap(ax, 45), M.Snap(ay, 45)
    end
    local gx = M.PlaneW(right[1], right[2], right[3], rad(ax))
    local gy = M.PlaneW(up[1], up[2], up[3], rad(ay))
    return M.Normalize(M.Mul(gy, M.Mul(gx, rStart)))
end

-- Lösungsmenge von lo <= off + coef·ξ <= hi als Intervall (ggf. unbeschränkt) oder nil.
local function solve(coef, off, lo, hi)
    if abs(coef) < 1e-9 then
        if off >= lo and off <= hi then return -math.huge, math.huge end
        return nil
    end
    local a, b = (lo - off) / coef, (hi - off) / coef
    if a > b then a, b = b, a end
    return a, b
end

-- Schnitt des Körpers B × [−d/2, d/2] mit dem 3D-Raum (Welt-w = Betrachter-w), reduziert auf
-- die Richtung n̂ der Neigung. s = |n| und c4 = R4[4][4] (s² + c4² = 1), delta = t_ent − t_view,
-- [lo, hi] = Ausdehnung von B entlang n̂. Lokale Punkte: (a, b) = −delta·(s, c4) + ξ·(c4, −s),
-- a ∈ [lo, hi], b ∈ [−d/2, d/2]. Liefert das ξ-Intervall des Schnitts oder nil (leer).
function M.SliceInterval(s, c4, delta, lo, hi, halfD)
    local a0, a1 = solve(c4, -delta * s, lo, hi)
    if not a0 then return nil end
    local b0, b1 = solve(-s, -delta * c4, -halfD, halfD)
    if not b0 then return nil end
    local x0, x1 = math.max(a0, b0), math.min(a1, b1)
    if x0 > x1 or not isFinite(x0) or not isFinite(x1) then return nil end
    return x0, x1
end

-- Netzformat: 8 Zahlen, Leerzeichen-getrennt. Leerer String = Identität.
function M.Serialize(r)
    if M.IsIdentity(r) then return "" end
    return string.format("%.7g %.7g %.7g %.7g %.7g %.7g %.7g %.7g",
        r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8])
end

function M.Deserialize(s)
    if type(s) ~= "string" or s == "" then return M.Identity() end
    local r = {}
    for part in string.gmatch(s, "%S+") do
        r[#r + 1] = tonumber(part)
        if #r > 8 then return nil end
    end
    return M.Validate(r)
end
