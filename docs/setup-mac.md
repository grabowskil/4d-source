# Mac-Setup (Apple Silicon)

## GMod-Client

GMod läuft auf dem Mac nur als Intel-Build unter Rosetta 2. Ohne GModPatchTool stürzt er beim Start ab.

1. Installiere GMod in Steam und lass das Spiel geschlossen.
2. Stell unter Eigenschaften → Betas den Branch **„x86-64 - Chromium + 64-bit Binaries“** ein.
3. Lade `GModPatchTool-macOS.zip` von den [Releases](https://github.com/solsticegamestudios/GModPatchTool/releases) und zieh die App nach `/Programme`.
4. Starte die App. Beim ersten Mal musst du sie unter Systemeinstellungen ▸ Datenschutz & Sicherheit erlauben.
5. **Nach jedem GMod-Update und jeder Dateiprüfung musst du erneut patchen.** Bequem geht das mit einem AppleScript, das du als Programm sicherst:

```applescript
do shell script "/Applications/GModPatchTool.app/Contents/MacOS/gmodpatchtool --launch-gmod --skip-exit-prompt"
```

Nach dem Upgrade auf macOS 27 musst du Rosetta neu installieren: `softwareupdate --install-rosetta`.

Startoptionen:

```text
-novid -condebug -conclearlog -windowed -noborder -w 2560 -h 1600
```

Auf dem Mac gibt es **kein Lua-Auto-Refresh**. Hot-Reload läuft deshalb über den Dev-Server (`docker compose up -d gmod`).

## Werkzeuge

| Zweck | Werkzeug |
|---|---|
| Container | OrbStack (amd64 via Rosetta) oder Docker Desktop |
| Editor | VS Code + `sumneko.lua` + [glua-api-snippets](https://github.com/luttje/glua-api-snippets) (LuaLS-Addon-Manager) |
| Lint | [glualint](https://github.com/FPtje/GLuaFixer/releases) (`OSX-x86_64`-Build, läuft unter Rosetta) in den PATH legen |
| Packen | [fastgmad](https://github.com/WilliamVenner/fastgmad) in den PATH legen |
| Claude Code | `jq` (für die Hooks), `python3` (für `tools/rcon.py`), optional `lua-language-server` |

## Optional: CS:S-Inhalte

Manche Maps brauchen CS:S-Texturen. So holst du dir den kostenlosen Dedicated Server per SteamCMD:

```bash
mkdir -p ~/Steam && cd ~/Steam
curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_osx.tar.gz" | tar zxvf -
./steamcmd.sh +@sSteamCmdForcePlatformType linux +force_install_dir ~/srcds/css \
  +login anonymous +app_update 232330 validate +quit
```

Danach trägst du ihn in `…/GarrysMod/garrysmod/cfg/mount.cfg` ein. Den Pfad unter `~/Library/Application Support/Steam/` musst du lokal prüfen.

```text
"mountcfg"
{
	"cstrike"	"/Users/<du>/srcds/css/cstrike"
}
```
