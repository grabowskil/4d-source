-- Phasen-Paare NPC ↔ Spieler (beide Realms). Kollision läuft über GM:ShouldCollide, das auch
-- clientseitig für die Bewegungsvorhersage des Spielers gerufen wird; daher shared.
FourD = FourD or {}

local cvThickness = GetConVar("fourd_thickness")

function FourD.Thickness()
    return cvThickness and cvThickness:GetFloat() or 0
end

-- Wer gegenüber NPCs eine Phase hat. Tests ersetzen das temporär durch einen Spieler-Ersatz.
function FourD.IsPhaseActor(ent)
    return ent:IsPlayer()
end

-- true für gültige Paare aus NPC und Phasen-Akteur (Reihenfolge egal).
function FourD.IsPhasedPair(a, b)
    if not IsValid(a) or not IsValid(b) or a == b then return false end
    return (a:IsNPC() and FourD.IsPhaseActor(b)) or (b:IsNPC() and FourD.IsPhaseActor(a))
end

function FourD.EntsInPhase(a, b)
    return FourD.InPhase(FourD.Get(a), FourD.Get(b), FourD.Thickness())
end

-- Ergebnis hängt nur von t beider Seiten und d ab; wer t oder d ändert, ruft vorher bzw.
-- danach CollisionRulesChanged (sv_fourd_npc, cl_fourd_npc). Nie dynamisch entfernen.
hook.Add("ShouldCollide", "fourd_npc_collide", function(a, b)
    if FourD.IsPhasedPair(a, b) and not FourD.EntsInPhase(a, b) then return false end
end)
