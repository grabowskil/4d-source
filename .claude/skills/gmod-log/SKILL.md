---
name: gmod-log
description: Zeigt die letzten Lua-Fehler des Dev-Servers (Docker) und schlägt minimale Fixes vor.
argument-hint: "[zeitraum, z. B. 10m]"
allowed-tools: Bash(./tools/log.sh *)
---
## Lua-Fehler des Dev-Servers
!`./tools/log.sh 10m`

Nenne pro Fehler Datei:Zeile, Ursache und den minimalen Fix. Keine weiteren Logs anfordern,
außer der Fehler ist ohne Kontext nicht einzuordnen – dann gezielt `./tools/log.sh $ARGUMENTS`.
