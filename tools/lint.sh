#!/usr/bin/env bash
# glualint-Wrapper. Ohne Argument wird lua/ gelintet. glualint findet glualint.json im Repo-Root selbst.
# Neuere Versionen nutzen `glualint lint <pfad>`, ältere `glualint <pfad>` – wird automatisch erkannt.
set -euo pipefail
cd "$(dirname "$0")/.."

[[ $# -gt 0 ]] || set -- lua/

if glualint --help 2>&1 | grep -qE '^[[:space:]]+lint([[:space:]]|$)'; then
  exec glualint lint "$@"
else
  exec glualint "$@"
fi
