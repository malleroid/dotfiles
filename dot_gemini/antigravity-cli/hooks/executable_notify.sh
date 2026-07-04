#!/usr/bin/env bash
set -euo pipefail

pane_label=""
if [ -n "${ZELLIJ_PANE_ID:-}" ]; then
  pane_label=$(zellij action list-panes -t -j 2>/dev/null | jq -r \
    --argjson id "$ZELLIJ_PANE_ID" \
    '.[] | select((.is_plugin | not) and .id == $id)
     | .title
     | gsub("[⠀-⣿✳✶✻✽✢]"; "")
     | gsub("^\\s+|\\s+$"; "")
     | gsub("\\s+"; " ")') || pane_label=""
  [ -n "$pane_label" ] && pane_label="$pane_label "
fi

# Agent state tracking via state files — Stop only (Antigravity has no permission hook)
STATE_DIR="/tmp/agent-state"
if [ -n "${ZELLIJ_SESSION_NAME:-}" ] && [ -n "${ZELLIJ_PANE_ID:-}" ]; then
  rm -f "$STATE_DIR/${ZELLIJ_SESSION_NAME}_${ZELLIJ_PANE_ID}.json"
fi

message="${pane_label}complete"

if [ "${AGY_NOTIFY_DRY_RUN:-}" = "1" ]; then
  printf '%s\n' "$message"
  exit 0
fi

command -v say >/dev/null 2>&1 || exit 0
say "$message" >/dev/null 2>&1 &

exit 0
