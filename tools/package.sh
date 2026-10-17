#!/usr/bin/env bash
# Packt das Addon lokal als build/myphys.gma (respektiert "ignore" aus addon.json).
# Erst-Upload (erzeugt die Workshop-ID) und Updates macht nur der Mensch bzw. CI:
#   fastgmad publish -addon build/myphys.gma -icon workshop/icon.jpg
#   fastgmad update -id <ID> -addon build/myphys.gma -changes "…"
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
fastgmad create -folder . -out build/myphys.gma -warninvalid
