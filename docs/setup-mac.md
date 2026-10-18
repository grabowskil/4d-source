# Mac setup (Apple Silicon)

## GMod client

On the Mac, GMod only runs as an Intel build under Rosetta 2. Without GModPatchTool it crashes on launch.

1. Install GMod in Steam and keep the game closed.
2. Under Properties → Betas, select the branch **"x86-64 - Chromium + 64-bit Binaries"**.
3. Download `GModPatchTool-macOS.zip` from the [releases](https://github.com/solsticegamestudios/GModPatchTool/releases) and drag the app into `/Applications`.
4. Launch the app. The first time, you have to allow it under System Settings ▸ Privacy & Security.
5. **You have to re-patch after every GMod update and every file verification.** The convenient way is an AppleScript saved as an application:

```applescript
do shell script "/Applications/GModPatchTool.app/Contents/MacOS/gmodpatchtool --launch-gmod --skip-exit-prompt"
```

After upgrading to macOS 27 you have to reinstall Rosetta: `softwareupdate --install-rosetta`.

Launch options:

```text
-novid -condebug -conclearlog -windowed -noborder -w 2560 -h 1600
```

On the Mac there is **no Lua auto-refresh**. Hot reload therefore goes through the dev server (`docker compose up -d gmod`).

## Tools

| Purpose | Tool |
|---|---|
| Containers | OrbStack (amd64 via Rosetta) or Docker Desktop |
| Editor | VS Code + `sumneko.lua` + [glua-api-snippets](https://github.com/luttje/glua-api-snippets) (LuaLS addon manager) |
| Lint | Put [glualint](https://github.com/FPtje/GLuaFixer/releases) (`OSX-x86_64` build, runs under Rosetta) in your PATH |
| Packaging | Put [fastgmad](https://github.com/WilliamVenner/fastgmad) in your PATH |
| Claude Code | `jq` (for the hooks), `python3` (for `tools/rcon.py`), optionally `lua-language-server` |

## Optional: CS:S content

Some maps need CS:S textures. Here's how to get the free dedicated server via SteamCMD:

```bash
mkdir -p ~/Steam && cd ~/Steam
curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_osx.tar.gz" | tar zxvf -
./steamcmd.sh +@sSteamCmdForcePlatformType linux +force_install_dir ~/srcds/css \
  +login anonymous +app_update 232330 validate +quit
```

Then add it to `…/GarrysMod/garrysmod/cfg/mount.cfg`. Check the path under `~/Library/Application Support/Steam/` locally.

```text
"mountcfg"
{
	"cstrike"	"/Users/<you>/srcds/css/cstrike"
}
```
