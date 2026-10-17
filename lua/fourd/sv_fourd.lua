-- Serverseitige Zuweisung und Tracking der 4. Koordinate t.
FourD = FourD or {}
FourD.Values = FourD.Values or {}    -- ent -> t; überlebt lua_refresh_file

local cvDefault = CreateConVar("fourd_default_t", "0", FCVAR_ARCHIVE,
    "Default-Wert der 4. Koordinate t für neue Entities")

local function isFiniteNumber(v)
    return isnumber(v) and v == v and v ~= math.huge and v ~= -math.huge
end

function FourD.GetDefault()
    local t = cvDefault:GetFloat()
    if not isFiniteNumber(t) then return 0 end
    return t
end

-- Setzt t für ein gültiges Entity. Gibt true bei Erfolg zurück, sonst false.
function FourD.Set(ent, t)
    if not IsValid(ent) then return false end
    if not isFiniteNumber(t) then return false end

    local old = FourD.Values[ent]
    FourD.Values[ent] = t
    ent:SetNW2Float(FourD.NW_KEY, t)

    hook.Run("FourD_Changed", ent, old, t)
    return true
end

-- Weist den Default zu, sofern das Entity noch keinen Wert hat.
function FourD.Assign(ent)
    if not IsValid(ent) then return end
    if FourD.Values[ent] ~= nil then return end
    FourD.Set(ent, FourD.GetDefault())
end

-- ent -> Tick der Einreihung. timer.Simple(0) kann laut Wiki noch im selben Frame laufen,
-- daher eigene Warteschlange, die garantiert erst in einem späteren Tick abgearbeitet wird.
FourD.Pending = FourD.Pending or {}

local function enqueue(ent)
    FourD.Pending[ent] = engine.TickCount()
end

hook.Add("OnEntityCreated", "fourd_assign", enqueue)

hook.Add("Tick", "fourd_pending", function()
    local now = engine.TickCount()
    for ent, tick in pairs(FourD.Pending) do
        if now > tick then
            FourD.Pending[ent] = nil
            FourD.Assign(ent)    -- prüft IsValid
        end
    end
end)

hook.Add("EntityRemoved", "fourd_cleanup", function(ent)
    FourD.Values[ent] = nil
    FourD.Pending[ent] = nil
end)

-- Bestehende Entities (Erstladen und Refresh). Assign überspringt bereits getrackte Werte.
for _, ent in ipairs(ents.GetAll()) do
    enqueue(ent)
end

local DUMP_LIMIT = 20

concommand.Add("fourd_dump", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    local list = {}
    for ent, t in pairs(FourD.Values) do
        if IsValid(ent) then
            list[#list + 1] = { ent = ent, t = t }
        end
    end
    table.sort(list, function(a, b) return a.ent:EntIndex() < b.ent:EntIndex() end)

    local out = { string.format("fourd: %d entities", #list) }
    for i = 1, math.min(#list, DUMP_LIMIT) do
        local ent, pos = list[i].ent, list[i].ent:GetPos()
        out[#out + 1] = string.format("%s %d %.2f %.2f %.2f %g",
            ent:GetClass(), ent:EntIndex(), pos.x, pos.y, pos.z, list[i].t)
    end

    for _, line in ipairs(out) do
        if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, line) else print(line) end
    end
end)
