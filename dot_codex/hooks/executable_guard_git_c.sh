#!/usr/bin/env bash
set -euo pipefail

input=$(cat)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

[ -z "$command" ] && exit 0

if printf '%s\n' "$command" | grep -qE '(^|[[:space:]])git[[:space:]]+-C([[:space:]]|$)'; then
  echo "Blocked: git -C is prohibited." >&2
  echo "Command: $command" >&2
  echo "Run the command from the target directory instead of using git -C." >&2
  exit 2
fi

exit 0
