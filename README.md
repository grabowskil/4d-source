# 4d-source: FourD

Garry's Mod physics addon (GLua) that adds a fourth spatial dimension. Every entity has a 4th coordinate `t` and a 4D orientation `R4`. The **FourD Physgun** shifts props and NPCs along `w` and rotates them in the w planes. Anything that is not "in phase" is hidden or drawn as a 3D slice, and can neither hit nor collide. The repo doubles as the addon folder.

**Steam Workshop:** [FourD (3821760241)](https://steamcommunity.com/sharedfiles/filedetails/?id=3821760241)
Development happens on a Mac, testing on a Linux srcds in a container. Lint, tests and the Workshop upload run in GitHub Actions.

| Layer | Component | Job |
|---|---|---|
| Mac (native) | Claude Code, VS Code + LuaLS, glualint (Rosetta), fastgmad | Write, check statically, package |
| Mac (Rosetta) | GMod client, branch `x86-64` + GModPatchTool | View, client/HUD tests |
| OrbStack (`linux/amd64`) | `ceifa/garrysmod:debian-x64`, bind mount | Hot reload, server log, GLuaTest |
| GitHub Actions | glualint, GLuaTest (`x86-64`), workshop-upload | Gate before merge, release |

Setting up the Mac client and tools is covered in [docs/setup-mac.md](docs/setup-mac.md).

## Quick start

```bash
docker compose up -d gmod          # dev server, repo is mounted as addons/myphys
./tools/log.sh                     # Lua errors from the last 10 minutes
./tools/lint.sh                    # glualint over lua/
./tools/test.sh lua/tests/fourd/sh_fourd_phase_spec.lua
```

In the GMod client, connect via the **Mac's LAN IP** (`ipconfig getifaddr en0`), for example:

```text
connect <LAN-IP>:27115
```

Then pick the FourD Physgun from the spawn menu under *Weapons → FourD* (controls: see [FourD](#fourd)).

On first connect a popup asks for local network access; you have to allow it. We ran into these pitfalls:

- `127.0.0.1` does not work: GMod's packets over loopback never reached the container, not even on port 27115.
- Port 27015 is taken on the Mac: the GMod client itself holds it. That's why the dev server uses 27115.
- `sv_lan 0` is required: Docker Desktop rewrites the source IP to a public address, and with `sv_lan 1` you otherwise get "LAN servers are restricted to local clients". `hide_server 1` keeps the server out of the public server browser.
- RCON only listens on `127.0.0.1:27115/tcp`.

When you save a file on the Mac, the server reloads it via auto-refresh (inotify). It also sends client files to connected clients. This was **verified** with Docker Desktop (2026-10-17): an edit to a `cl_` file was running in the connected Mac client within a few seconds, without reconnecting. A few notes:

- A file can run several times per save, so the code must be refresh-safe.
- With the console open or the window unfocused, GMod on the Mac sometimes shows a stale image.

The easiest way to check whether a file was reloaded is a temporary `print` line that shows up in the client's `console.log`.

If auto-refresh doesn't kick in, reload like this:

```bash
./tools/reload.sh lua/fourd/sv_fourd_npc.lua
```

## FourD

Weapon *FourD Physgun* (spawn menu → Weapons → FourD):

| Input | Effect |
|---|---|
| Hold left | Grab a prop (like the physgun), mouse wheel = distance |
| E + mouse | Rotate the held object in the planes (right, w) and (up, w); Shift snaps to 45° |
| R | Reset the held object's R4 |
| Hold right | Select a target, NPCs included (permissions via `PhysgunPickup`) |
| Right + mouse wheel | Target's `t` ±0.5 per notch, Shift ±0.1 |
| Right + R | Set the target's `t` to your own `t` |
| Right + E + mouse | Rotate the target's R4 |

- **In phase** means: the 3D slice of the body (box × thickness `d` in `w`, rotated by R4) in the player's space is not empty. Without rotation this means |Δt| ≤ d/2.
- **NPCs out of phase** are invisible, including their weapon and ragdoll. They neither deal nor take damage, don't collide with the player and treat them as neutral. Back in phase, the original relationships apply again.
- **Props** keep their normal behavior without rotation and are only drawn sliced when rotated.

| ConVar | Default | Realm | Meaning |
|---|---|---|---|
| `fourd_thickness` | 2 | Server, replicated | Thickness `d` of all bodies in `w` |
| `fourd_max_t` | 64 | Server, replicated | Limit for \|t\| with the physgun |
| `fourd_default_t` | 0 | Server | `t` of new entities |
| `fourd_cl_slice` | 1 | Client | Draw the slice of rotated objects |
| `fourd_cl_npc_hide` | 1 | Client | Hide NPCs that are out of phase |

Derivation, decisions and approximations are in [docs/fourd-rotation.md](docs/fourd-rotation.md).

## Layout

```text
lua/autorun/fourd_init.lua             Loader (shared)
lua/fourd/sh_fourd*.lua                FourD core: t, 4D math, phase rule, NPC pairs (shared)
lua/fourd/sv_fourd*.lua                Setting t/R4, NPC damage, collision, relationships
lua/fourd/cl_fourd*.lua                Slice rendering, hiding out-of-phase bodies
lua/weapons/fourd_physgun/             FourD Physgun
lua/tests/fourd/                       GLuaTest specs (not in the Workshop package)
tools/                                 lint, log, test, rcon, reload, package
.claude/                               Rules, hooks, skills, agents for Claude Code
```

## Claude Code

- `CLAUDE.md` stays short. Realm-specific rules live in `.claude/rules/*.md` and are only loaded for matching files.
- Hook `lint-lua.sh` lints every edited `.lua` file. On exit 2, Claude fixes it itself.
- Hook `trim-logs.sh` trims `docker compose logs …` down to error lines.
- Skills: `/gmod-log` and `/gmod-test <file>` (runs in the Haiku subagent `gmod-test-runner`).
- Agents: `glua-reviewer` (read-only review), `wiki-researcher` (wiki.facepunch.com only).
- Recommended plugins: `/plugin install lua-lsp@claude-plugins-official` (needs `lua-language-server` in PATH). Optionally, as a GLua API skill, `/plugin marketplace add Alleexxi/glua-claude-skill` followed by `/plugin install glua@glua-claude-skill`.

## Release

1. `workshop/icon.jpg` (512×512, baseline JPEG) is a placeholder and may be replaced.
2. Done, the Workshop ID is `3821760241`. For new items: do the first upload once locally with `./tools/package.sh` and `fastgmad publish …`. Without fastgmad, `gmad` and `gmpublish` from the GMod client (`GarrysMod_Signed.app/Contents/MacOS/`) work too. This creates the Workshop ID.
3. The repo variable `WORKSHOP_ID` is set. The secrets `STEAM_USERNAME` and `STEAM_VDF` are still missing; only with them does every GitHub release upload automatically, without them the release job fails.

## Optional: VPhysics-Jolt

Extract the Linux64 release of [VPhysics-Jolt](https://github.com/misyltoad/VPhysics-Jolt/releases) into `docker/jolt/`, then start:

```bash
docker compose --profile jolt up -d gmod-jolt
```

The server runs on port 27016. Test every physics feature against stock VPhysics **and** against Jolt.

## License

[MIT](LICENSE)
