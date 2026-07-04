#!/usr/bin/env bash
set -euo pipefail

input=$(cat)
event_name=$(printf '%s' "$input" | jq -r '.hook_event_name // .notification_type // empty')

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

case "$event_name" in
  PermissionRequest | permission_prompt)
    message="${pane_label}check"
    ;;
  Stop | idle_prompt)
    message="${pane_label}complete"
    ;;
  *)
    message="${pane_label}notify"
    ;;
esac

if [ "${CODEX_NOTIFY_DRY_RUN:-}" = "1" ]; then
  printf '%s\n' "$message"
  exit 0
fi

command -v say >/dev/null 2>&1 || exit 0
say "$message" >/dev/null 2>&1 &

exit 0
