#!/usr/bin/env bash
# Claude Code notification with voice and tab info

INPUT=$(cat)
NOTIFICATION_TYPE=$(echo "$INPUT" | jq -r '.notification_type // "unknown"')

# Zellij pane identification
PANE_LABEL=""
if [ -n "$ZELLIJ_PANE_ID" ]; then
  PANE_LABEL="${ZELLIJ_SESSION_NAME} pane${ZELLIJ_PANE_ID} "
fi

# Short English messages for speed
case "$NOTIFICATION_TYPE" in
  permission_prompt)
    MSG="${PANE_LABEL}check"
    ;;
  idle_prompt)
    MSG="${PANE_LABEL}complete"
    ;;
  *)
    MSG="${PANE_LABEL}notify"
    ;;
esac

say "$MSG" &

exit 0
