#!/usr/bin/env bash
set -euo pipefail

pane_label=""
if [ -n "${ZELLIJ_PANE_ID:-}" ]; then
  pane_label=$(zellij action list-panes -t -j 2>/dev/null | jq -r \
    --argjson id "$ZELLIJ_PANE_ID" \
    --arg session "${ZELLIJ_SESSION_NAME:-zellij}" \
    '.[] | select((.is_plugin | not) and .id == $id)
     | "\($session) \(.tab_name) \(.title)"
     | gsub("[⠀-⣿✳✶✻✽✢]"; "")
     | gsub("\\s+"; " ")') || pane_label=""
  if [ -n "$pane_label" ]; then
    pane_label="${pane_label% } "
  else
    pane_label="${ZELLIJ_SESSION_NAME:-zellij} pane${ZELLIJ_PANE_ID} "
  fi
fi

message="${pane_label}complete"

if [ "${AGY_NOTIFY_DRY_RUN:-}" = "1" ]; then
  printf '%s\n' "$message"
  exit 0
fi

command -v say >/dev/null 2>&1 || exit 0
say "$message" >/dev/null 2>&1 &

exit 0
