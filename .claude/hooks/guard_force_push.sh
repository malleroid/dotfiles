#!/usr/bin/env bash
# Block git push --force / -f

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[ -z "$COMMAND" ] && exit 0

if echo "$COMMAND" | grep -qE 'git\s+push\s+.*(-f\b|--force)'; then
  echo "🚫 Blocked: Force push detected" >&2
  echo "Command: $COMMAND" >&2
  echo "Force pushing can overwrite upstream changes and cannot be undone." >&2
  echo "Please confirm with the user explicitly before proceeding." >&2
  exit 2
fi

exit 0
