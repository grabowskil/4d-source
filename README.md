# 4d-source: FourD

Garry's-Mod-Physikaddon (GLua) mit einer vierten Raumdimension. Jedes Entity hat eine 4. Koordinate `t` und eine 4D-Orientierung `R4`. Die **FourD Physgun** verschiebt Props und NPCs in `w` und dreht sie in den w-Ebenen. Was nicht „in Phase“ ist, wird ausgeblendet oder als 3D-Schnitt gezeigt und kann weder treffen noch kollidieren. Das Repo ist zugleich der Addon-Ordner.
Entwickelt wird auf dem Mac, getestet auf einem Linux-srcds im Container. Lint, Tests und der Workshop-Upload laufen in GitHub Actions.

| Ebene | Komponente | Aufgabe |
|---|---|---|
| Mac (nativ) | Claude Code, VS Code + LuaLS, glualint (Rosetta), fastgmad | Schreiben, statisch prüfen, packen |
| Mac (Rosetta) | GMod-Client, Branch `x86-64` + GModPatchTool | Ansehen, Client-/HUD-Tests |
| OrbStack (`linux/amd64`) | `ceifa/garrysmod:debian-x64`, Bind-Mount | Hot-Reload, Server-Log, GLuaTest |
| GitHub Actions | glualint, GLuaTest (`x86-64`), workshop-upload | Gate vor dem Merge, Release |

Die Einrichtung von Mac-Client und Werkzeugen steht in [docs/setup-mac.md](docs/setup-mac.md).

## Schnellstart

```bash
docker compose up -d gmod          # Dev-Server, Repo ist als addons/myphys gemountet
./tools/log.sh                     # Lua-Fehler der letzten 10 Minuten
./tools/lint.sh                    # glualint über lua/
./tools/test.sh lua/tests/fourd/sh_fourd_phase_spec.lua
```

Im GMod-Client verbindest du dich über die **LAN-IP des Macs** (`ipconfig getifaddr en0`), zum Beispiel:

```text
connect <LAN-IP>:27115
```

Danach im Spawnmenü unter *Weapons → FourD* die FourD Physgun nehmen (Bedienung siehe [FourD](#fourd)).

Beim ersten Verbinden fragt ein Popup nach Zugriff aufs lokale Netzwerk, das musst du bestätigen. Folgende Fallstricke haben wir beobachtet:

- `127.0.0.1` funktioniert nicht: Die Pakete von GMod kamen über Loopback nie im Container an, auch nicht über Port 27115.
- Port 27015 ist auf dem Mac belegt: Den hält der GMod-Client selbst. Deshalb nutzt der Dev-Server 27115.
- `sv_lan 0` ist nötig: Docker Desktop schreibt die Absender-IP auf eine öffentliche Adresse um, und mit `sv_lan 1` kommt sonst „LAN-Server sind nur für lokale Clients verfügbar“. `hide_server 1` hält den Server aus dem öffentlichen Serverbrowser heraus.
- RCON hört nur auf `127.0.0.1:27115/tcp`.

Speicherst du eine Datei auf dem Mac, lädt der Server sie per Auto-Refresh (inotify) neu. Client-Dateien schickt er auch an verbundene Clients. Das ist mit Docker Desktop **geprüft** (17.10.2026): Ein Edit an einer `cl_`-Datei lief nach wenigen Sekunden im verbundenen Mac-Client, ohne Reconnect. Ein paar Hinweise dazu:

- Pro Speichervorgang kann die Datei mehrfach laufen, deshalb muss der Code refresh-sicher sein.
- Bei offener Konsole oder ohne Fenster-Fokus zeigt GMod auf dem Mac teils ein veraltetes Bild.

Ob eine Datei neu geladen wurde, prüfst du am einfachsten mit einer temporären `print`-Zeile, die im Client-`console.log` auftaucht.

Greift Auto-Refresh nicht, lädst du so neu:

```bash
./tools/reload.sh lua/fourd/sv_fourd_npc.lua
```

## FourD

Waffe *FourD Physgun* (Spawnmenü → Weapons → FourD):

| Eingabe | Wirkung |
|---|---|
| Links halten | Prop greifen (wie die Physgun), Mausrad = Abstand |
| E + Maus | gehaltenes Objekt in den Ebenen (rechts, w) und (oben, w) drehen, Shift rastet auf 45° |
| R | R4 des gehaltenen Objekts zurücksetzen |
| Rechts halten | Ziel wählen, auch NPCs (Rechte über `PhysgunPickup`) |
| Rechts + Mausrad | `t` des Ziels ±0,5 pro Raste, Shift ±0,1 |
| Rechts + R | `t` des Ziels auf das eigene `t` |
| Rechts + E + Maus | R4 des Ziels drehen |

- **In Phase** heißt: Der 3D-Schnitt des Körpers (Box × Dicke `d` in `w`, gedreht mit R4) im Raum des Spielers ist nicht leer. Ohne Drehung bedeutet das |Δt| ≤ d/2.
- **NPCs außerhalb der Phase** sind unsichtbar, samt Waffe und Ragdoll. Sie richten keinen Schaden an und nehmen keinen, kollidieren nicht mit dem Spieler und behandeln ihn als neutral. In Phase gelten wieder die ursprünglichen Beziehungen.
- **Props** behalten ohne Drehung ihr normales Verhalten und werden nur gedreht geschnitten dargestellt.

| ConVar | Default | Realm | Bedeutung |
|---|---|---|---|
| `fourd_thickness` | 2 | Server, repliziert | Dicke `d` aller Körper in `w` |
| `fourd_max_t` | 64 | Server, repliziert | Grenze für \|t\| bei der Physgun |
| `fourd_default_t` | 0 | Server | `t` neuer Entities |
| `fourd_cl_slice` | 1 | Client | Schnitt gedrehter Objekte zeichnen |
| `fourd_cl_npc_hide` | 1 | Client | NPCs außerhalb der Phase ausblenden |

Herleitung, Entscheidungen und Näherungen stehen in [docs/fourd-rotation.md](docs/fourd-rotation.md).

## Layout

```text
lua/autorun/fourd_init.lua             Loader (shared)
lua/fourd/sh_fourd*.lua                FourD-Kern: t, 4D-Mathe, Phasenregel, NPC-Paare (shared)
lua/fourd/sv_fourd*.lua                t/R4 setzen, NPC-Schaden, Kollision, Beziehungen
lua/fourd/cl_fourd*.lua                Schnittdarstellung, Ausblenden außerhalb der Phase
lua/weapons/fourd_physgun/             FourD Physgun
lua/tests/fourd/                       GLuaTest-Specs (nicht im Workshop-Paket)
tools/                                 lint, log, test, rcon, reload, package
.claude/                               Rules, Hooks, Skills, Agents für Claude Code
```

## Claude Code

- `CLAUDE.md` bleibt kurz. Realm-spezifische Regeln liegen in `.claude/rules/*.md` und werden nur bei passenden Dateien geladen.
- Hook `lint-lua.sh` lintet jede bearbeitete `.lua`-Datei. Bei Exit 2 korrigiert Claude selbst.
- Hook `trim-logs.sh` kürzt `docker compose logs …` auf Fehlerzeilen.
- Skills: `/gmod-log` und `/gmod-test <datei>` (läuft im Haiku-Subagent `gmod-test-runner`).
- Agents: `glua-reviewer` (read-only Review), `wiki-researcher` (nur wiki.facepunch.com).
- Empfohlene Plugins: `/plugin install lua-lsp@claude-plugins-official` (braucht `lua-language-server` im PATH). Dazu als optionaler GLua-API-Skill `/plugin marketplace add Alleexxi/glua-claude-skill` und dann `/plugin install glua@glua-claude-skill`.

## Release

1. `workshop/icon.jpg` (512×512, Baseline-JPEG) ist ein Platzhalter und darf ersetzt werden.
2. Mach den Erst-Upload einmal lokal mit `./tools/package.sh` und `fastgmad publish …`. Ohne fastgmad gehen auch `gmad` und `gmpublish` aus dem GMod-Client (`GarrysMod_Signed.app/Contents/MacOS/`). Dabei entsteht die Workshop-ID.
3. Trag im Repo die Variable `WORKSHOP_ID` und die Secrets `STEAM_USERNAME` und `STEAM_VDF` ein. Ab dann lädt jedes GitHub-Release automatisch hoch.

## Optional: VPhysics-Jolt

Entpacke das Linux64-Release von [VPhysics-Jolt](https://github.com/misyltoad/VPhysics-Jolt/releases) nach `docker/jolt/` und starte dann:

```bash
docker compose --profile jolt up -d gmod-jolt
```

Der Server läuft auf Port 27016. Teste jede Physikfunktion gegen Standard-VPhysics **und** gegen Jolt.

## Lizenz

[MIT](LICENSE)
