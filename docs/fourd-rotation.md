# 4D-Rotation für die FourD Physgun

## Recherche

### 1. Drehung in 4D
**Bestätigt.** In 4D dreht man in Ebenen, nicht um Achsen. Die Winkelgeschwindigkeit ist ein Bivektor mit n(n−1)/2 = 6 Komponenten (xy, xz, yz, xw, yw, zw) [1]. Einfache Drehung: eine 2-Ebene bleibt fest [5]. Doppelte Drehung: gleichzeitig in zwei orthogonalen Ebenen [1]. Isoklin: beide Winkel gleich bzw. entgegengesetzt [5].

### 2. Darstellung im Spiel
**Bestätigt, mit einer Korrektur.** Jede Rotation in SO(4) lässt sich zerlegen in eine Links- und eine Rechtsmultiplikation mit Einheitsquaternionen, eindeutig bis auf das gemeinsame Vorzeichen (L, R) ~ (−L, −R) [4][5]. Cayley 1855 ist belegt [5], Van Elfrinkhof nur als Matrixname [4].

Ten Bosch speichert einen 4D-Rotor als 8 Zahlen: Skalar, 6 Bivektor-Komponenten, 1 Quadvektor [1]. Komposition per geometrischem Produkt, Anwendung x′ = R x R̃ [1]. **Korrektur:** Einfaches Normalisieren reicht beim Rotor nicht, weil doppelte Drehungen nicht auf der Einheitssphäre liegen. Ten Bosch faktorisiert deshalb nach Perwass [1]. Ein Quaternionenpaar lässt sich dagegen durch getrenntes Normalisieren beider Faktoren reparieren (folgt aus [4], eigene Schlussfolgerung).

Für den Netz-Sync braucht man 8 Zahlen (Paar oder Rotor) oder 16 Zahlen (4×4-Matrix). Für die Matrix-Reorthonormalisierung wurde keine Quelle gelesen; Gram-Schmidt gilt als Standard (unbestätigt).

### 3. 3D-Objekt bei Drehung in einer w-Ebene
**Bestätigt (eigene Herleitung, nicht aus Quelle).** Ein Punkt (x, y, z, 0) wird in der xw-Ebene um θ gedreht zu (x cos θ, y, z, x sin θ). Für θ ≠ 0, π schneidet die Hyperebene w = t davon nur die Fläche x = t / sin θ. Das Volumen ist also null.

Ten Bosch und Miegakure nutzen echte 4D-Körper und zeigen deren 3D-Schnitt, der sich beim Drehen ändert [1][3].

Für „3D-Körper × Dicke d in w“ ist der Schnitt nicht leer. Er hängt von d, der Verschiebung t und dem Drehwinkel ab.

### 4. Eingabe-Mapping
In Miegakure tauscht genau eine Taste eine sichtbare Achse (Y) mit w [2]. X bleibt fest, Z ist die Schwerkraftrichtung [2]. Der Tausch ist eine 90°-Drehung, die weich interpoliert wird [2]. Dabei bleiben zwei Achsen als Referenz sichtbar [2]. Sehen und Bewegen sind bewusst gekoppelt: keine Extra-Tasten für „blinde“ w-Bewegung [2]. Freies Drehen und Verschieben des Schnitts kommen erst später [3].

In 4D Toys wird nur innerhalb des aktuellen 3D-Schnitts gezogen und gedreht [1]. Die Lage entlang w steuert ein Schieberegler [1].

**Passend für „E halten + Maus“:** Mausachsen auf genau eine bzw. zwei w-Ebenen legen (z. B. xw, yw). Die übrigen Achsen bleiben als Referenz fest. Die Drehung sollte kontinuierlich und gedämpft sein, analog zur interpolierten 90°-Drehung [2].

## Entscheidungen
- **Orientierung:** Pro Entity `R4` im lokalen Objektrahmen, Welt = Angles (eingebettet als diag(A, 1)) · R4. Identität = Verhalten wie bisher (kein Eintrag, NW2 leer).
- **Darstellung:** Quaternionenpaar (L, R), v′ = L·v·R̄ mit v = w + xi + yj + zk, 8 Zahlen. Nach jeder Änderung beide Faktoren getrennt normieren, kanonisch Lw ≥ 0; jeder Wert wird auf endlich geprüft. Begründung: stabil ohne Gram-Schmidt, Komposition = zwei Quaternionprodukte, halb so viele Zahlen wie die Matrix (§2).
- **Sync:** ein `NW2String` `fourd_r` (8 × `%.7g`, leer = Identität), weil acht einzelne Floats nicht atomar ankommen.
- **Steuerung:** E + Maus X dreht in der Ebene (Blick-rechts, w), Maus Y in (Blick-oben, w). Konjugiert gilt A⁻¹·G·A = Drehung in der Ebene (A⁻¹e, w), also R4 ← G_oben · G_rechts · R4_Start. Die Winkel werden ab dem Drücken von E akkumuliert, ±200 Einheiten pro UserCmd geclampt, 0,2° pro Einheit. Shift rastet die akkumulierten Winkel auf 45° ein, die Ansicht steht still (`SWEP:FreezeMovement`). Damit gibt es zwei w-Ebenen wie im Vorschlag aus §4, aber frei statt nur in 90°-Schritten.
- **Dicke:** `fourd_thickness` = d (Default 2, im Spiel als bester Effekt bestätigt). Körper = B × [−d/2, d/2]. Mit r = 4. Zeile von R4, n = (r₁, r₂, r₃), s = |n|, c₄ = r₄ und Δ = t_ent − t_Betrachter liegt ein lokaler Punkt (q, q_w) im Schnitt, wenn Δ + n·q + c₄·q_w = 0. In der Ebene (a = n̂·q, b = q_w) ist der Schnitt die Strecke (a, b) = −Δ(s, c₄) + ξ(c₄, −s) mit a ∈ [lo, hi] (Ausdehnung von B entlang n̂) und |b| ≤ d/2. Spezialfälle: Bei c₄ = 1 ist der Schnitt B, falls |Δ| ≤ d/2. Bei 90° (c₄ = 0) hat er entlang n̂ die Länge d, Ausdehnung und Dicke tauschen also. Bei d = 0 bleibt nur eine Fläche (§3).
- **Im Spiel:** Kollision und Physik unverändert. Debug-HUD (t, Doppeldrehwinkel α/β, w-Neigung, Drag-Winkel) nur mit aktiver Waffe. **Annäherung:** Der Client staucht das Modell per `EnableMatrix("RenderMultiply")` entlang n̂ auf das ξ-Intervall. Das gilt exakt für einfache Drehungen eines Quaders. Ignoriert werden die Scherung bei Doppeldrehungen und die Spiegelung bei c₄ < 0. Abschaltbar mit `fourd_cl_slice 0`.

## NPCs
- **In Phase:** Ohne Drehung gilt `FourD.InPhase(tA, tB, d)` ⇔ |tA − tB| ≤ d/2 (+1e-6 gegen Rundung), d = `fourd_thickness`. Mit R4 ≠ Identität entscheidet `FourD.InPhaseSlice`: Der Schnitt des Körpers mit dem 3D-Raum des Spielers aus „Dicke“ ist nicht leer. Damit ist „sichtbar“ dasselbe wie „treffbar und kollidierend“, und ein gedrehter NPC außerhalb der t-Phase kann teilweise hereinragen. Das weicht vom Default „nur t“ ab: Ohne diese Kopplung bliebe jede Drehung außerhalb der Phase unsichtbar. Der Körper ist der NPC, der Betrachter der Spieler; dessen R4 bleibt unberücksichtigt. NaN/inf gelten als „in Phase“, also normales Spiel statt Unverwundbarkeit.
- **Box des Körpers:** Die OBB eines NPCs ist sein Bewegungshull (Citizen ±13 × 72) und deutlich breiter als der Körper. Gedrehte NPCs wirkten deshalb dünner als d. `FourD.BodyBounds` nimmt bei NPCs die Vereinigung der Hitboxen (Citizen in x etwa ±7,5) und speichert sie pro Modell und Skalierung. Berechnet wird sie nie in `ShouldCollide`, sondern vorab: beim Phasenwechsel, im 1-s-Timer bzw. im 0,1-s-Poll des Clients, jeweils mit anschließendem `CollisionRulesChanged`. Ist sie mehr als doppelt so groß wie die OBB, wird sie verworfen. Die Pose ist die beim ersten Abruf, und Server und Client rechnen getrennt. Ragdolls und Props nutzen die OBB.
- **Wirkung:** Gilt nur für Paare aus Körper (NPC oder dessen Ragdoll) und Spieler (`FourD.IsPhaseActor`). Außerhalb der Phase blockiert `EntityTakeDamage` den Schaden in beide Richtungen. Als Verursacher zählt der erste von Angreifer, Inflictor und deren Owner, der mit dem Ziel ein Paar bildet. `ShouldCollide` gibt `false` zurück. Der NPC bekommt `AddEntityRelationship(ply, D_NU, 99)` und vergisst den Spieler als Gegner. Die Originalbeziehung aus `Disposition` (D-Enum und Priorität) wird nur beim ersten Wechsel nach außen gespeichert (`FourD.NpcRel`) und beim Zurückkommen wiederhergestellt. Beim Entfernen einer der beiden Seiten wird aufgeräumt.
- **Vererbung:** Ein neues Entity mit Owner (Waffe, Granate, Rakete) übernimmt bei der ersten Zuweisung das t des Owners. Server-Ragdolls (`CreateEntityRagdoll`) übernehmen t und R4 und werden per NW2Bool `fourd_body` wie der NPC behandelt. Clientseitige Ragdolls (`CreateClientsideRagdoll`) bekommen t und R4 lokal gespeichert, werden sofort per `SetNoDraw` und zusätzlich per Null-Matrix ausgeblendet oder geschnitten. Sie haben keine Spielwirkung.
- **Kollision shared:** `ShouldCollide` läuft auch clientseitig für die Bewegungsvorhersage, deshalb steht der Hook in `sh_fourd_npc.lua`. Server und Client rufen `CollisionRulesChanged` auf, wenn sich t, R4 oder d ändern. Der Server tut das in `FourD_Changed` und `FourD_Rotated` und per 1-s-Abfrage von d. Der Client prüft alle 0,1 s. `cvars.AddChangeCallback` ist für replizierte ConVars laut Wiki unzuverlässig.
- **Darstellung:** Clientseitig werden Körper außerhalb der Phase per `SetNoDraw` ausgeblendet, NPCs samt aktiver Waffe und auch bei R4 = Identität (`fourd_cl_npc_hide 0` schaltet das ab). In Phase greift der Schnitt aus `cl_fourd_rot`. Props ziehen nicht gleich: Sie kollidieren weiter in 3D, und unsichtbare Hindernisse wären schlimmer als ein sichtbares Prop mit anderem t. Für Props gilt also weiter „ohne Drehung exakt wie bisher“.
- **Steuerung (FourD Physgun):** Rechtsklick halten wählt das gehaltene Prop oder das anvisierte Entity. Spieler und Welt sind ausgenommen, die Rechte prüft `PhysgunPickup` (Sandbox, Prop-Protection). Ausgeblendete NPCs bleiben per Trace wählbar. Das Mausrad ändert t um ±0,5 pro Raste, mit Shift um ±0,1, höchstens alle 0,05 s und geclampt auf ±`fourd_max_t` (Default 64, reine Funktion `FourD.WheelStepT`). R setzt t auf das t des Spielers, E + Maus dreht R4 wie bei Props. Die Eingabe läuft serverautoritativ über das UserCmd, ohne net-Message.
- **Annäherungen:** `EnableMatrix` deaktiviert laut Wiki die IK des Entities und skaliert prozedurale Bones nicht. Gedrehte NPCs werden deshalb nur ungefähr geschnitten dargestellt (Füße können schweben oder einsinken). Die Hitbox-Box stammt aus einer festen Pose, weit ausgestreckte Gliedmaßen können also über das Schnittintervall hinausragen. Ein clientseitiges `SetNoDraw` kann ein Netzupdate der Effekt-Flags überschreiben, es wird alle 0,1 s erneut gesetzt. Ändert ein anderes Addon oder das Spiel die Beziehung, während der NPC außerhalb der Phase ist, überschreibt die Wiederherstellung das. Traces und Kugeln treffen weiter, nur der Schaden entfällt.

## Quellen
1. Marc ten Bosch: „N-Dimensional Rigid Body Dynamics“. ACM Transactions on Graphics 39(4) (SIGGRAPH), 2020. https://marctenbosch.com/ndphysics/ (PDF: https://marctenbosch.com/ndphysics/NDrigidbody.pdf), DOI 10.1145/3386569.3392483
2. Marc ten Bosch: „Nature as Designer (There was only one way to design Miegakure)“. Blog, 2014. https://marctenbosch.com/news/?p=905
3. Marc ten Bosch: Miegakure-Website (FAQ). https://miegakure.com/
4. Johan Ernest Mebius: „A matrix-based proof of the quaternion representation theorem for four-dimensional rotations“. arXiv:math/0501249, 2005. https://arxiv.org/abs/math/0501249
5. Yifan Li, Zijia Li, Ke Ye: „Kempe factorizations for rational curves on SO₄(ℝ)“. arXiv:2608.30577, 2026 (Abschnitte 2–4). https://arxiv.org/abs/2608.30577
