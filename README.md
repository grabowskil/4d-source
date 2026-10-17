# MyPhys

Garry's-Mod-Physikaddon (GLua). Das Repo ist zugleich der Addon-Ordner.
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
./tools/test.sh lua/tests/myphys/sv_util_spec.lua
```

Im GMod-Client: `connect 127.0.0.1:27015`. Danach im Spawnmenü unter *Entities → MyPhys* den Schwimmkörper spawnen. Unter *Tools → MyPhys* liegt der Physik-Tuner.

Ändern sich Dateien auf dem Mac, lädt der Server sie per Auto-Refresh (inotify) neu. Ob die Events durch den Bind-Mount in die VM gelangen, ist **ungeprüft**. Greift es nicht, lädst du so neu:

```bash
./tools/reload.sh lua/myphys/sv_core.lua
```

## Layout

```text
lua/autorun/myphys_init.lua            Loader (shared)
lua/myphys/sh_config.lua, sh_util.lua  Konfiguration, reine Helfer
lua/myphys/sv_core.lua                 net-Endpunkt Gravitation (SuperAdmin, rate-limitiert)
lua/myphys/sv_backend.lua              erkennt HolyLib / VPhysics-Jolt (optional)
lua/myphys/cl_hud.lua                  Overlay + Konsolenbefehl myphys_gravity <z>
lua/entities/myphys_float/             Schwimmkörper: eigener Auftrieb per Motion Controller
lua/weapons/gmod_tool/stools/          Physik-Tuner (Masse, Dämpfung)
lua/tests/myphys/                      GLuaTest-Specs (nicht im Workshop-Paket)
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

1. Lege ein Icon unter `workshop/icon.jpg` ab: 512×512, Baseline-JPEG.
2. Mach den Erst-Upload einmal lokal mit `./tools/package.sh` und `fastgmad publish …`. Dabei entsteht die Workshop-ID.
3. Trag im Repo die Variable `WORKSHOP_ID` und die Secrets `STEAM_USERNAME` und `STEAM_VDF` ein. Ab dann lädt jedes GitHub-Release automatisch hoch.

## Optional: VPhysics-Jolt

Entpacke das Linux64-Release von [VPhysics-Jolt](https://github.com/misyltoad/VPhysics-Jolt/releases) nach `docker/jolt/` und starte dann:

```bash
docker compose --profile jolt up -d gmod-jolt
```

Der Server läuft auf Port 27016. Teste jede Physikfunktion gegen Standard-VPhysics **und** gegen Jolt.
