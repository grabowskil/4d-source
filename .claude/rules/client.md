---
paths: ["lua/**/cl_*.lua", "lua/autorun/client/**", "lua/entities/**/cl_init.lua"]
---
- Keine Physikobjekte erzeugen, keine autoritative Logik – nur Anzeige und Eingabe.
- Server-Zustand über `GetGlobal2*`/NetworkVars lesen, Änderungen per net an den Server schicken.
- HUDPaint & Co.: nichts zurückgeben (Rückgabe ≠ nil stoppt andere Hooks).
- Jede neue `cl_`-Datei braucht `AddCSLuaFile` im Loader bzw. in `init.lua`.
