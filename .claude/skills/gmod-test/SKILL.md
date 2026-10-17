---
name: gmod-test
description: Führt genau eine GLuaTest-Datei im Docker-Testserver aus und meldet nur Fehlschläge. Nach Codeänderungen nutzen.
argument-hint: "<lua/tests/myphys/datei.lua>"
context: fork
agent: gmod-test-runner
allowed-tools: Bash(./tools/test.sh *)
---
Führe `./tools/test.sh $ARGUMENTS` aus (dauert beim ersten Mal einige Minuten: Image-Download).

Antworte mit maximal 30 Zeilen: Ergebnis (grün/rot), fehlgeschlagene Testnamen,
erste Fehlerzeile, Datei:Zeile. Keine vollständigen Logs, keine Fix-Vorschläge.
