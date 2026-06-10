#!/usr/bin/env bash
# Claude Code notification with voice and tab info

INPUT=$(cat)
# Notification events carry notification_type; Stop events only hook_event_name
EVENT=$(echo "$INPUT" | jq -r '.notification_type // .hook_event_name // "unknown"')

# Zellij pane identification: "<session> <tab name> <pane title>" (zellij 0.44+)
# Pane title carries the Claude Code session name via OSC; strip the
# spinner/status glyphs Claude prepends so `say` reads names only.
PANE_LABEL=""
if [ -n "$ZELLIJ_PANE_ID" ]; then
  PANE_LABEL=$(zellij action list-panes -t -j 2>/dev/null | jq -r \
    --argjson id "$ZELLIJ_PANE_ID" \
    '.[] | select((.is_plugin | not) and .id == $id)
     | "\(env.ZELLIJ_SESSION_NAME) \(.tab_name) \(.title)"
     | gsub("[⠀-⣿✳✶✻✽✢]"; "")
     | gsub("\\s+"; " ")')
  if [ -n "$PANE_LABEL" ]; then
    PANE_LABEL="${PANE_LABEL% } "
  else
    PANE_LABEL="${ZELLIJ_SESSION_NAME} pane${ZELLIJ_PANE_ID} "
  fi
fi

# Short English messages for speed
case "$EVENT" in
  permission_prompt)
    MSG="${PANE_LABEL}check"
    ;;
  Stop)
    MSG="${PANE_LABEL}complete"
    ;;
  idle_prompt)
    # Stop hook already announced completion; stay silent
    exit 0
    ;;
  *)
    MSG="${PANE_LABEL}notify"
    ;;
esac

say "$MSG" &

exit 0
