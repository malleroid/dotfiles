#!/usr/bin/env bash
set -euo pipefail

input=$(cat)
event_name=$(printf '%s' "$input" | jq -r '.notification_type // .type // .event_type // .hook_event_name // empty' 2>/dev/null || true)

pane_label=""
if [ -n "${ZELLIJ_PANE_ID:-}" ]; then
  pane_label="${ZELLIJ_SESSION_NAME:-zellij} pane${ZELLIJ_PANE_ID} "
fi

case "$event_name" in
  PermissionRequest | ToolPermission | permission_prompt | action_required | input_required)
    message="${pane_label}check"
    ;;
  AfterAgent | Stop | idle_prompt | session_complete | task_complete)
    message="${pane_label}complete"
    ;;
  *)
    message="${pane_label}notify"
    ;;
esac

if [ "${GEMINI_NOTIFY_DRY_RUN:-}" = "1" ]; then
  printf '%s\n' "$message" >&2
  printf '{}\n'
  exit 0
fi

if command -v say >/dev/null 2>&1; then
  say "$message" >/dev/null 2>&1 </dev/null &
fi

printf '{}\n'
