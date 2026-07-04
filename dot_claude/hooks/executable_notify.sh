#!/usr/bin/env bash
# Claude Code notification with voice and agent state tracking

INPUT=$(cat)
EVENT=$(echo "$INPUT" | jq -r '.notification_type // .hook_event_name // "unknown"')

PANE_LABEL=""
if [ -n "$ZELLIJ_PANE_ID" ]; then
  PANE_LABEL=$(zellij action list-panes -t -j 2>/dev/null | jq -r \
    --argjson id "$ZELLIJ_PANE_ID" \
    '.[] | select((.is_plugin | not) and .id == $id)
     | .title
     | gsub("[⠀-⣿✳✶✻✽✢]"; "")
     | gsub("^\\s+|\\s+$"; "")
     | gsub("\\s+"; " ")')
  [ -n "$PANE_LABEL" ] && PANE_LABEL="$PANE_LABEL "
fi

# Agent state tracking via state files
STATE_DIR="/tmp/agent-state"
if [ -n "${ZELLIJ_SESSION_NAME:-}" ] && [ -n "${ZELLIJ_PANE_ID:-}" ]; then
  mkdir -p "$STATE_DIR"
  STATE_FILE="$STATE_DIR/${ZELLIJ_SESSION_NAME}_${ZELLIJ_PANE_ID}.json"
  case "$EVENT" in
    permission_prompt)
      echo '{"agent":"claude","status":"asking_permissions","ts":'$(date +%s)'}' > "$STATE_FILE"
      ;;
    elicitation_dialog)
      echo '{"agent":"claude","status":"waiting_user_answers","ts":'$(date +%s)'}' > "$STATE_FILE"
      ;;
    Stop)
      rm -f "$STATE_FILE"
      ;;
  esac
fi

case "$EVENT" in
  permission_prompt)
    MSG="${PANE_LABEL}check"
    ;;
  elicitation_dialog)
    MSG="${PANE_LABEL}check"
    ;;
  Stop)
    MSG="${PANE_LABEL}complete"
    ;;
  idle_prompt)
    exit 0
    ;;
  *)
    MSG="${PANE_LABEL}notify"
    ;;
esac

say "$MSG" &

exit 0
