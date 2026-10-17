#!/usr/bin/env bash
# Führt GLuaTest im Docker-Container aus (GMod-Branch x86-64).
# Nutzung: tools/test.sh lua/tests/myphys/sv_float_spec.lua [weitere …]
# Ohne Argument laufen alle Specs – für Claude immer nur die betroffene Datei angeben.
# Volle Ausgabe landet in .dev/last-test.log, auf stdout nur Fehler und Zusammenfassung.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEV="$ROOT/.dev"
GLUATEST="$DEV/GLuaTest"
STAGE="$DEV/test-project"
LOG="$DEV/last-test.log"

mkdir -p "$DEV/gluatest-artifacts"
touch "$DEV/gluatest-requirements.txt" "$DEV/gluatest-server.cfg"

if [[ ! -d "$GLUATEST" ]]; then
  git clone --quiet --depth 1 https://github.com/CFC-Servers/GLuaTest.git "$GLUATEST" \
    || { echo "GLuaTest-Clone fehlgeschlagen" >&2; exit 1; }
fi

# Addon ohne Tests in ein Staging-Verzeichnis kopieren, dann nur die gewünschten Specs dazu
rm -rf "$STAGE"
mkdir -p "$STAGE/lua/tests/myphys"
rsync -a --exclude 'tests/' "$ROOT/lua/" "$STAGE/lua/"
if [[ $# -gt 0 ]]; then
  for f in "$@"; do
    src="$f"; [[ "$f" = /* ]] || src="$ROOT/$f"
    [[ -f "$src" ]] || { echo "Testdatei nicht gefunden: $f" >&2; exit 64; }
    cp "$src" "$STAGE/lua/tests/myphys/"
  done
else
  cp "$ROOT"/lua/tests/myphys/*.lua "$STAGE/lua/tests/myphys/"
fi

export PROJECT_DIR="$STAGE"
export REQUIREMENTS="$DEV/gluatest-requirements.txt"
export CUSTOM_SERVER_CONFIG="$DEV/gluatest-server.cfg"
export GMOD_ARTIFACT_DIR="$DEV/gluatest-artifacts"
export GMOD_BRANCH="x86-64"
export GAMEMODE="sandbox" MAP="gm_construct"
export TIMEOUT="${TIMEOUT:-}" COLLECTION_ID="" SSH_PRIVATE_KEY="" GITHUB_TOKEN="" EXTRA_STARTUP_ARGS=""
export DOCKER_DEFAULT_PLATFORM="linux/amd64"

COMPOSE=(docker compose -f "$GLUATEST/docker/docker-compose.yml" -p myphys-gluatest)
"${COMPOSE[@]}" up --abort-on-container-exit --exit-code-from runner >"$LOG" 2>&1
STATUS=$?
"${COMPOSE[@]}" down >/dev/null 2>&1

grep -E -i -A3 'fail|\[error\]|lua/.*:[0-9]+:|attempt to ' "$LOG" | head -60
echo "--- Zusammenfassung ---"
grep -E -i 'passed|failed|tests? (run|completed)|gluatest' "$LOG" | tail -10
echo "Exit: $STATUS (volles Log: .dev/last-test.log)"
exit "$STATUS"
