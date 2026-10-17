#!/usr/bin/env bash
# Lua-Fehler des Dev-Servers, gekürzt auf das Relevante. Nutzung: tools/log.sh [zeitraum] [service]
set -uo pipefail
cd "$(dirname "$0")/.."

SINCE="${1:-10m}"
SERVICE="${2:-gmod}"

docker compose logs --no-color --since "$SINCE" "$SERVICE" 2>&1 \
  | grep -E -A4 '\[ERROR\]|lua/.*:[0-9]+:|attempt to ' \
  | tail -60 \
  | grep . || echo "(keine Lua-Fehler in den letzten $SINCE)"
