# 4D rotation for the FourD Physgun

## Research

### 1. Rotation in 4D
**Confirmed.** In 4D you rotate in planes, not about axes. Angular velocity is a bivector with n(n−1)/2 = 6 components (xy, xz, yz, xw, yw, zw) [1]. Simple rotation: one 2-plane stays fixed [5]. Double rotation: simultaneously in two orthogonal planes [1]. Isoclinic: both angles equal or opposite [5].

### 2. In-game representation
**Confirmed, with one correction.** Every rotation in SO(4) can be decomposed into a left and a right multiplication by unit quaternions, unique up to the shared sign (L, R) ~ (−L, −R) [4][5]. Cayley 1855 is documented [5], Van Elfrinkhof only as the name of a matrix [4].

Ten Bosch stores a 4D rotor as 8 numbers: scalar, 6 bivector components, 1 quadvector [1]. Composition via the geometric product, application x′ = R x R̃ [1]. **Correction:** Plain normalization is not enough for the rotor, because double rotations do not lie on the unit sphere. Ten Bosch therefore factorizes following Perwass [1]. A quaternion pair, on the other hand, can be repaired by normalizing both factors separately (follows from [4], our own conclusion).

Network sync needs 8 numbers (pair or rotor) or 16 numbers (4×4 matrix). No source was read on matrix re-orthonormalization; Gram-Schmidt is considered standard (unconfirmed).

### 3. 3D object rotated in a w plane
**Confirmed (own derivation, not from a source).** A point (x, y, z, 0) rotated by θ in the xw plane becomes (x cos θ, y, z, x sin θ). For θ ≠ 0, π the hyperplane w = t only cuts the surface x = t / sin θ out of it. The volume is therefore zero.

Ten Bosch and Miegakure use real 4D bodies and show their 3D slice, which changes as they rotate [1][3].

For "3D body × thickness d in w" the slice is not empty. It depends on d, the offset t and the rotation angle.

### 4. Input mapping
In Miegakure exactly one key swaps a visible axis (Y) with w [2]. X stays fixed, Z is the direction of gravity [2]. The swap is a 90° rotation that is smoothly interpolated [2]. Two axes stay visible as a reference [2]. Seeing and moving are deliberately coupled: no extra keys for "blind" movement in w [2]. Free rotation and shifting of the slice only come later [3].

In 4D Toys you only drag and rotate within the current 3D slice [1]. The position along w is controlled by a slider [1].

**Suitable for "hold E + mouse":** Map the mouse axes to exactly one or two w planes (e.g. xw, yw). The remaining axes stay fixed as a reference. The rotation should be continuous and damped, analogous to the interpolated 90° rotation [2].

## Decisions
- **Orientation:** Per-entity `R4` in the local object frame, world = Angles (embedded as diag(A, 1)) · R4. Identity = behavior as before (no entry, NW2 empty).
- **Representation:** Quaternion pair (L, R), v′ = L·v·R̄ with v = w + xi + yj + zk, 8 numbers. After every change both factors are normalized separately, canonically Lw ≥ 0; every value is checked for finiteness. Rationale: stable without Gram-Schmidt, composition = two quaternion products, half as many numbers as the matrix (§2).
- **Sync:** One `NW2String` `fourd_r` (8 × `%.7g`, empty = identity), because eight separate floats do not arrive atomically.
- **Controls:** E + mouse X rotates in the plane (view-right, w), mouse Y in (view-up, w). By conjugation, A⁻¹·G·A = rotation in the plane (A⁻¹e, w), so R4 ← G_up · G_right · R4_start. The angles are accumulated from the moment E is pressed, clamped to ±200 units per UserCmd, 0.2° per unit. Shift snaps the accumulated angles to 45°, and the view stays still (`SWEP:FreezeMovement`). This gives two w planes as proposed in §4, but free rather than only in 90° steps.
- **Thickness:** `fourd_thickness` = d (default 2, confirmed in-game as the best effect). Body = B × [−d/2, d/2]. With r = 4th row of R4, n = (r₁, r₂, r₃), s = |n|, c₄ = r₄ and Δ = t_ent − t_viewer, a local point (q, q_w) lies in the slice if Δ + n·q + c₄·q_w = 0. In the plane (a = n̂·q, b = q_w) the slice is the segment (a, b) = −Δ(s, c₄) + ξ(c₄, −s) with a ∈ [lo, hi] (extent of B along n̂) and |b| ≤ d/2. Special cases: at c₄ = 1 the slice is B if |Δ| ≤ d/2. At 90° (c₄ = 0) it has length d along n̂, so extent and thickness swap. At d = 0 only a surface remains (§3).
- **In-game:** Collision and physics unchanged. Debug HUD (t, double rotation angles α/β, w tilt, drag angles) only with the weapon active. **Approximation:** The client squashes the model via `EnableMatrix("RenderMultiply")` along n̂ onto the ξ interval. This is exact for simple rotations of a box. Ignored are the shear in double rotations and the mirroring at c₄ < 0. Can be turned off with `fourd_cl_slice 0`.

## NPCs
- **In phase:** Without rotation, `FourD.InPhase(tA, tB, d)` ⇔ |tA − tB| ≤ d/2 (+1e-6 against rounding), d = `fourd_thickness`. With R4 ≠ identity, `FourD.InPhaseSlice` decides: the slice of the body with the player's 3D space (see "Thickness" above) is not empty. So "visible" is the same as "hittable and colliding", and a rotated NPC outside the t phase can partly reach in. This deviates from the default "t only": without this coupling, every rotation outside the phase would stay invisible. The body is the NPC, the viewer is the player; the player's R4 is not taken into account. NaN/inf count as "in phase", i.e. normal play instead of invulnerability.
- **Body box:** An NPC's OBB is its movement hull (Citizen ±13 × 72) and noticeably wider than the body. Rotated NPCs therefore looked thinner than d. `FourD.BodyBounds` uses the union of the hitboxes for NPCs (Citizen roughly ±7.5 in x) and caches it per model and scale. It is never computed in `ShouldCollide`, but ahead of time: on phase change, in the 1 s timer or in the client's 0.1 s poll, each followed by `CollisionRulesChanged`. If it is more than twice the size of the OBB, it is discarded. The pose is the one at first lookup, and server and client compute separately. Ragdolls and props use the OBB.
- **Effect:** Applies only to pairs of body (NPC or its ragdoll) and player (`FourD.IsPhaseActor`). Out of phase, `EntityTakeDamage` blocks damage in both directions. The source is the first of attacker, inflictor and their owners that forms a pair with the target. `ShouldCollide` returns `false`. The NPC gets `AddEntityRelationship(ply, D_NU, 99)` and forgets the player as an enemy. The original relationship from `Disposition` (D enum and priority) is only stored on the first switch to out of phase (`FourD.NpcRel`) and restored on return. When either side is removed, it is cleaned up.
- **Inheritance:** A new entity with an owner (weapon, grenade, rocket) takes over the owner's t on first assignment. Server ragdolls (`CreateEntityRagdoll`) take over t and R4 and are treated like the NPC via the NW2Bool `fourd_body`. Clientside ragdolls (`CreateClientsideRagdoll`) get t and R4 stored locally, and are immediately hidden via `SetNoDraw` plus a zero matrix, or sliced. They have no gameplay effect.
- **Shared collision:** `ShouldCollide` also runs clientside for movement prediction, which is why the hook lives in `sh_fourd_npc.lua`. Server and client call `CollisionRulesChanged` when t, R4 or d change. The server does this in `FourD_Changed` and `FourD_Rotated` and by polling d every 1 s. The client checks every 0.1 s. According to the wiki, `cvars.AddChangeCallback` is unreliable for replicated ConVars.
- **Rendering:** Clientside, bodies out of phase are hidden via `SetNoDraw`, NPCs including their active weapon and also at R4 = identity (`fourd_cl_npc_hide 0` turns this off). In phase, the slice from `cl_fourd_rot` applies. Props don't follow suit: they keep colliding in 3D, and invisible obstacles would be worse than a visible prop with a different t. So for props, "exactly as before without rotation" still holds.
- **Controls (FourD Physgun):** Holding right-click selects the held prop or the entity being aimed at. Players and the world are excluded; permissions are checked by `PhysgunPickup` (Sandbox, prop protection). Hidden NPCs remain selectable via trace. The mouse wheel changes t by ±0.5 per notch, with Shift by ±0.1, at most every 0.05 s and clamped to ±`fourd_max_t` (default 64, pure function `FourD.WheelStepT`). R sets t to the player's t, E + mouse rotates R4 as with props. Input is server-authoritative via the UserCmd, without a net message.
- **Approximations:** According to the wiki, `EnableMatrix` disables the entity's IK and does not scale procedural bones. Rotated NPCs are therefore only drawn approximately sliced (feet may float or sink in). The hitbox box comes from a fixed pose, so far-stretched limbs can extend beyond the slice interval. A clientside `SetNoDraw` can be overwritten by a network update of the effect flags, so it is reapplied every 0.1 s. If another addon or the game changes the relationship while the NPC is out of phase, the restore overwrites that. Traces and bullets still hit; only the damage is dropped.

## Sources
1. Marc ten Bosch: "N-Dimensional Rigid Body Dynamics". ACM Transactions on Graphics 39(4) (SIGGRAPH), 2020. https://marctenbosch.com/ndphysics/ (PDF: https://marctenbosch.com/ndphysics/NDrigidbody.pdf), DOI 10.1145/3386569.3392483
2. Marc ten Bosch: "Nature as Designer (There was only one way to design Miegakure)". Blog, 2014. https://marctenbosch.com/news/?p=905
3. Marc ten Bosch: Miegakure website (FAQ). https://miegakure.com/
4. Johan Ernest Mebius: "A matrix-based proof of the quaternion representation theorem for four-dimensional rotations". arXiv:math/0501249, 2005. https://arxiv.org/abs/math/0501249
5. Yifan Li, Zijia Li, Ke Ye: "Kempe factorizations for rational curves on SO₄(ℝ)". arXiv:2608.30577, 2026 (sections 2–4). https://arxiv.org/abs/2608.30577
