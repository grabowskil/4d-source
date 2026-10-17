#!/usr/bin/env bash
# PreToolUse(Bash): kürzt `docker compose logs …` auf Fehlerzeilen, bevor die Ausgabe in den Kontext geht.
# Achtung: permissionDecision "allow" überspringt die Rechteabfrage. Deshalb nur einfache,
# rein lesende Log-Befehle ohne Verkettung, Umleitung oder Subshell umschreiben.
CMD=$(jq -r '.tool_input.command // empty')

meta='[;&|`$<>]'
[[ "$CMD" =~ $meta ]] && exit 0

logs='^docker compose logs( [A-Za-z0-9_.:=-]+)*$'
[[ "$CMD" =~ $logs ]] || exit 0
[[ " $CMD " =~ \ (-f|--follow)\  ]] && exit 0   # -f blockiert endlos

NEW="$CMD 2>&1 | grep -E -A5 '(\[ERROR\]|FAIL|lua/.*:[0-9]+:|attempt to )' | head -80 | grep . || echo '(keine Fehlerzeilen im Log)'"
jq -n --arg c "$NEW" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "allow",
    permissionDecisionReason: "read-only log command, trimmed to error lines",
    updatedInput: { command: $c }
  }
}'
exit 0
