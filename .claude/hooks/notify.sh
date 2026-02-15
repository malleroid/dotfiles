#!/usr/bin/env bash
# Claude Code notification with voice and tab info

INPUT=$(cat)
NOTIFICATION_TYPE=$(echo "$INPUT" | jq -r '.notification_type // "unknown"')

# WezTerm get tab ID
TAB_LABEL=""
if [ -n "$WEZTERM_PANE" ]; then
  TAB_ID=$(wezterm cli list --format json 2>/dev/null \
    | jq -r ".[] | select(.pane_id == $WEZTERM_PANE) | .tab_id" 2>/dev/null)
  if [ -n "$TAB_ID" ]; then
    TAB_LABEL="tab${TAB_ID} "
  fi
fi

# Short English messages for speed
case "$NOTIFICATION_TYPE" in
  permission_prompt)
    MSG="${TAB_LABEL}check"
    ;;
  idle_prompt)
    MSG="${TAB_LABEL}complete"
    ;;
  *)
    MSG="${TAB_LABEL}notify"
    ;;
esac

say "$MSG" &

exit 0
