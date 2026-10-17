---
paths: ["lua/**/sv_*.lua", "lua/autorun/server/**", "lua/entities/**/init.lua"]
---
- Kein VGUI/Derma, kein LocalPlayer(). net.Receive = untrusted endpoint; Rechte prüfen und rate-limiten.
- Zahlen aus net/ConVars immer über `MyPhys.SafeClamp` (NaN/inf verwerfen).
- PhysicsSimulate: Kräfte clampen (`MyPhys.ClampVector`); kein EnableCollisions/EnableGravity darin (Crashgefahr).
- `StartMotionController()` nach jedem Neuaufbau des PhysObj erneut aufrufen.
- `GM:ShouldCollide`: Ergebnis pro Paar konstant, Hook nie dynamisch hinzufügen/entfernen.
