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

## Quellen
1. Marc ten Bosch: „N-Dimensional Rigid Body Dynamics“. ACM Transactions on Graphics 39(4) (SIGGRAPH), 2020. https://marctenbosch.com/ndphysics/ (PDF: https://marctenbosch.com/ndphysics/NDrigidbody.pdf), DOI 10.1145/3386569.3392483
2. Marc ten Bosch: „Nature as Designer (There was only one way to design Miegakure)“. Blog, 2014. https://marctenbosch.com/news/?p=905
3. Marc ten Bosch: Miegakure-Website (FAQ). https://miegakure.com/
4. Johan Ernest Mebius: „A matrix-based proof of the quaternion representation theorem for four-dimensional rotations“. arXiv:math/0501249, 2005. https://arxiv.org/abs/math/0501249
5. Yifan Li, Zijia Li, Ke Ye: „Kempe factorizations for rational curves on SO₄(ℝ)“. arXiv:2608.30577, 2026 (Abschnitte 2–4). https://arxiv.org/abs/2608.30577
