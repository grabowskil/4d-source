-- Phasen-Paare Körper ↔ Spieler (beide Realms). Körper = NPC oder dessen Server-Ragdoll.
-- Kollision läuft über GM:ShouldCollide, das auch clientseitig für die Bewegungsvorhersage des
-- Spielers gerufen wird; daher shared.
FourD = FourD or {}

FourD.BODY_NW_KEY = "fourd_body"   -- NW2Bool: Ragdoll eines NPCs, verhält sich wie der NPC
FourD.BoundsCache = FourD.BoundsCache or {}   -- "Modell|Skalierung" -> { mins, maxs } (Hitboxen)

local cvThickness = GetConVar("fourd_thickness")

function FourD.Thickness()
    return cvThickness and cvThickness:GetFloat() or 0
end

-- Wer gegenüber Körpern eine Phase hat. Tests ersetzen das temporär durch einen Spieler-Ersatz.
function FourD.IsPhaseActor(ent)
    return ent:IsPlayer()
end

function FourD.IsPhaseBody(ent)
    return ent:IsNPC() or ent:GetNW2Bool(FourD.BODY_NW_KEY, false)
end

-- true für gültige Paare aus Körper und Phasen-Akteur (Reihenfolge egal).
function FourD.IsPhasedPair(a, b)
    if not IsValid(a) or not IsValid(b) or a == b then return false end
    return (FourD.IsPhaseBody(a) and FourD.IsPhaseActor(b))
        or (FourD.IsPhaseBody(b) and FourD.IsPhaseActor(a))
end

local function grow(lo, hi, v)
    lo.x, lo.y, lo.z = math.min(lo.x, v.x), math.min(lo.y, v.y), math.min(lo.z, v.z)
    hi.x, hi.y, hi.z = math.max(hi.x, v.x), math.max(hi.y, v.y), math.max(hi.z, v.z)
end

-- Vereinigung aller Hitboxen (Set 0) im lokalen Rahmen des Entities, in der aktuellen Pose.
-- nil, wenn Hitboxen oder Bone-Matrizen (noch) fehlen.
local function hitboxBounds(ent)
    local count = ent:GetHitBoxCount(0) or 0
    if count == 0 then return nil end
    local lo, hi = Vector(math.huge, math.huge, math.huge), Vector(-math.huge, -math.huge, -math.huge)
    for i = 0, count - 1 do
        local bone = ent:GetHitBoxBone(i, 0)
        local m = bone and ent:GetBoneMatrix(bone)
        local a, b = ent:GetHitBoxBounds(i, 0)
        if not m or not a then return nil end
        for k = 0, 7 do
            local p = Vector(k % 2 == 0 and a.x or b.x, k % 4 < 2 and a.y or b.y, k < 4 and a.z or b.z)
            grow(lo, hi, ent:WorldToLocal(m * p))
        end
    end
    if hi.x - lo.x < 1 or hi.y - lo.y < 1 or hi.z - lo.z < 1 then return nil end
    return lo, hi
end

local function boundsKey(ent)
    return (ent:GetModel() or "") .. "|" .. ent:GetModelScale()
end

-- Hitbox-Box vorab berechnen (außerhalb von ShouldCollide, das nur liest). Verworfen, wenn sie
-- mehr als doppelt so groß wie die OBB ist (Bones nicht aufgebaut, z. B. dormant). Gibt true
-- zurück, wenn der Cache dabei neu gefüllt wurde; dann muss der Aufrufer die Regeln erneuern.
function FourD.WarmBodyBounds(ent)
    if not IsValid(ent) or not ent:IsNPC() then return false end
    local key = boundsKey(ent)
    if FourD.BoundsCache[key] then return false end

    local lo, hi = hitboxBounds(ent)
    if not lo then return false end
    local size, obb = hi - lo, ent:OBBMaxs() - ent:OBBMins()
    if size.x > 2 * obb.x or size.y > 2 * obb.y or size.z > 2 * obb.z then return false end

    FourD.BoundsCache[key] = { lo, hi }
    return true
end

-- Box für den Schnitt im lokalen Rahmen. Bei NPCs ist die OBB der Bewegungshull und deutlich
-- breiter als der Körper; deshalb die Hitbox-Vereinigung aus dem Cache (FourD.WarmBodyBounds),
-- solange sie fehlt die OBB. Ragdolls (Pose ändert sich) und alle anderen Entities: OBB.
function FourD.BodyBounds(ent)
    local c = ent:IsNPC() and FourD.BoundsCache[boundsKey(ent)]
    if c then return c[1], c[2] end
    return ent:OBBMins(), ent:OBBMaxs()
end

-- R4 eines Körpers oder nil bei Identität (schneller Pfad über den NW2-String).
local function bodyRot(ent)
    if ent:GetNW2String(FourD.ROT_NW_KEY, "") == "" then return nil end
    return FourD.GetRot(ent)
end

-- Schnitt des Körpers mit dem 3D-Raum des Betrachters nicht leer (t, d und R4 des Körpers).
function FourD.BodyInPhase(body, viewer)
    local r = bodyRot(body)
    local mins, maxs
    if r then mins, maxs = FourD.BodyBounds(body) end
    return FourD.InPhaseSlice(FourD.Get(body), FourD.Get(viewer), FourD.Thickness(), r, mins, maxs)
end

-- Für Paare: der Phasen-Akteur ist der Betrachter, die andere Seite der Körper.
function FourD.EntsInPhase(a, b)
    if FourD.IsPhaseActor(a) then a, b = b, a end
    return FourD.BodyInPhase(a, b)
end

-- Ergebnis hängt nur von t beider Seiten, R4 des Körpers und d ab; wer das ändert, ruft
-- CollisionRulesChanged (sv_fourd_npc, cl_fourd_npc). Nie dynamisch entfernen.
hook.Add("ShouldCollide", "fourd_npc_collide", function(a, b)
    if FourD.IsPhasedPair(a, b) and not FourD.EntsInPhase(a, b) then return false end
end)
