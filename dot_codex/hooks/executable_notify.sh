#!/usr/bin/env bash
set -euo pipefail

input=$(cat)
event_name=$(printf '%s' "$input" | jq -r '.hook_event_name // .notification_type // empty')

pane_label=""
if [ -n "${ZELLIJ_PANE_ID:-}" ]; then
  pane_label="${ZELLIJ_SESSION_NAME:-zellij} pane${ZELLIJ_PANE_ID} "
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
