#!/usr/bin/env bash
set -euo pipefail

input=$(cat)
IFS=$'\x1f' read -r event_name session_id session_cwd session_source < <(
  printf '%s' "$input" |
    jq -r '[.hook_event_name // .notification_type // "", .session_id // "", .cwd // "", .source // ""] | join("\u001f")'
)

# Agent state tracking. CODEX_AGENT_STATE_DIR keeps tests inside the repository.
state_dir="${CODEX_AGENT_STATE_DIR:-/tmp/agent-state}"
state_file=""
legacy_state_file=""
if [ -n "$session_id" ]; then
  safe_session_id=$(printf '%s' "$session_id" | tr -c 'A-Za-z0-9._-' '_')
  state_file="$state_dir/codex_${safe_session_id}.json"
fi
if [ -n "${ZELLIJ_SESSION_NAME:-}" ] && [ -n "${ZELLIJ_PANE_ID:-}" ]; then
  legacy_state_file="$state_dir/${ZELLIJ_SESSION_NAME}_${ZELLIJ_PANE_ID}.json"
fi

state=""
case "$event_name" in
  SessionStart)
    if [ "$session_source" = "compact" ]; then
      state="busy"
    else
      state="idle"
    fi
    ;;
  UserPromptSubmit | PostToolUse)
    state="busy"
    ;;
  PermissionRequest | permission_prompt)
    state="asking_permissions"
    ;;
  Stop | idle_prompt)
    state="idle"
    ;;
  SessionEnd)
    if [ -n "$state_file" ]; then
      rm -f "$state_file"
    fi
    if [ -n "$legacy_state_file" ]; then
      rm -f "$legacy_state_file"
    fi
    ;;
esac

if [ -n "$state" ] && [ -n "$state_file" ]; then
  mkdir -p "$state_dir"
  tmp_state_file="${state_file}.tmp.$$"
  jq -n \
    --arg agent codex \
    --arg status "$state" \
    --arg sessionId "$session_id" \
    --arg cwd "$session_cwd" \
    --arg zellijSession "${ZELLIJ_SESSION_NAME:-}" \
    --arg paneId "${ZELLIJ_PANE_ID:-}" \
    --argjson ts "$(date +%s)" \
    '{agent: $agent, status: $status, sessionId: $sessionId, cwd: $cwd,
      zellijSession: $zellijSession, paneId: $paneId, ts: $ts}' > "$tmp_state_file"
  mv "$tmp_state_file" "$state_file"
  if [ -n "$legacy_state_file" ] && [ "$legacy_state_file" != "$state_file" ]; then
    rm -f "$legacy_state_file"
  fi
fi

message=""
case "$event_name" in
  PermissionRequest | permission_prompt)
    message="check"
    ;;
  Stop | idle_prompt)
    message="complete"
    ;;
esac

if [ -n "$message" ] && [ -n "${ZELLIJ_PANE_ID:-}" ]; then
  pane_label=$(zellij action list-panes -t -j 2>/dev/null | jq -r \
    --argjson id "$ZELLIJ_PANE_ID" \
    '.[] | select((.is_plugin | not) and .id == $id)
     | .title
     | gsub("[⠀-⣿✳✶✻✽✢]"; "")
     | gsub("^\\s+|\\s+$"; "")
     | gsub("\\s+"; " ")') || pane_label=""
  [ -n "$pane_label" ] && message="$pane_label $message"
fi

if [ "${CODEX_NOTIFY_DRY_RUN:-}" = "1" ]; then
  if [ -n "$message" ]; then
    printf '%s\n' "$message"
  fi
  exit 0
fi

[ -n "$message" ] || exit 0
command -v say >/dev/null 2>&1 || exit 0
say "$message" >/dev/null 2>&1 &

exit 0
