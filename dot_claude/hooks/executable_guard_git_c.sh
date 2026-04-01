#!/usr/bin/env bash
# Block git -C <path> option

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[ -z "$COMMAND" ] && exit 0

if echo "$COMMAND" | grep -qE 'git\s+-C\b'; then
  echo "🚫 Blocked: git -C is prohibited." >&2
  echo "Command: $COMMAND" >&2
  echo "git -C changes the command string and breaks permissions.allow pattern matching." >&2
  echo "Use 'cd <path>' then run git commands separately instead." >&2
  exit 2
fi

exit 0
