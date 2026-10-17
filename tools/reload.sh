#!/usr/bin/env bash
# Lädt eine bereits geladene Lua-Datei auf dem Dev-Server neu (Fallback, falls Auto-Refresh
# über den Bind-Mount nicht greift). Nutzung: tools/reload.sh lua/myphys/sv_core.lua
# (Ableitung) Ob lua_refresh_file den Pfad mit oder ohne führendes "lua/" erwartet, lokal prüfen.
set -euo pipefail
[[ $# -eq 1 ]] || { echo "Usage: $0 <pfad>" >&2; exit 64; }
exec "$(dirname "$0")/rcon.py" lua_refresh_file "$1"
