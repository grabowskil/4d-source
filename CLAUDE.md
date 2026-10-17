# MyPhys – GMod-Addon (GLua, LuaJIT 2.1 / Lua 5.1, Branch x86-64)

## Befehle
- Lint: `./tools/lint.sh` (ganzes `lua/`) oder `./tools/lint.sh <datei>`
- Server: `docker compose up -d gmod` · Logs: `/gmod-log` · Neustart Map: `./tools/rcon.py changelevel gm_construct`
- Tests: `/gmod-test <datei>` – immer nur die betroffene Testdatei, nie die ganze Suite
- Reload ohne Neustart: `./tools/reload.sh <pfad>` (RCON `lua_refresh_file`)
- Einzeiler auf dem Server: `./tools/rcon.py "lua_run print(physenv.GetGravity())"`

## Layout
- `lua/autorun/fourd_init.lua` Loader · `lua/fourd/{sh,sv,cl}_*.lua` Kern (`FourD`-Global, 4. Koordinate `t`)
- `lua/tests/fourd/` GLuaTest-Specs (nicht im Workshop-Paket)

## Regeln
- Keine GLua-Aliasse (`!=`, `&&`, `||`, `!`, `//`, `/* */`) – nur Standard-Lua-Syntax.
- Realm per Präfix: `sv_` Server, `cl_` Client, `sh_` beides. Client-Dateien brauchen `AddCSLuaFile`.
- Jede net-Message: `util.AddNetworkString` serverseitig; Sender + Argumente validieren.
- Refresh-sicher: Globals als `X = X or {}`, Hooks mit eindeutiger ID `fourd_*`.
- Physikobjekte NUR serverseitig erzeugen.
- Auftrieb/`AddSurfaceData` fehlen auf x86-64 → eigene Kraftmodelle per Motion Controller.
- API nicht raten: vor jeder unbekannten Funktion Skill `glua` oder wiki.facepunch.com prüfen (Agent `wiki-researcher`).
- Kein Upload: `fastgmad publish/update` macht nur der Mensch bzw. CI.
- Fertig = glualint sauber + betroffene Testdatei grün. Danach stoppen, nicht refactoren.

## Compact instructions
Behalte geänderte Dateien, offene Fehler (Datei:Zeile) und Testbefehle.
