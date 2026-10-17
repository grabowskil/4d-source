#!/usr/bin/env bash
# PostToolUse(Edit|Write): lintet die bearbeitete .lua-Datei.
# Exit 2 → stderr landet in Claudes Kontext und Claude korrigiert selbst.
FILE=$(jq -r '.tool_input.file_path // empty')
[[ "$FILE" == *.lua ]] || exit 0

if ! command -v glualint >/dev/null 2>&1; then
  echo "glualint nicht im PATH – Lint übersprungen" >&2
  exit 0
fi

if ! OUT=$("$CLAUDE_PROJECT_DIR/tools/lint.sh" "$FILE" 2>&1); then
  echo "$OUT" | head -40 >&2      # kurz halten: das geht in Claudes Kontext
  exit 2
fi
exit 0
