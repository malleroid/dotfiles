#!/usr/bin/env bash
set -euo pipefail

input=$(cat)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

[ -z "$command" ] && exit 0

if printf '%s\n' "$command" | grep -qE 'git[[:space:]]+push[[:space:]].*(-f([[:space:]]|$)|--force([[:space:]]|$))'; then
  echo "Blocked: force push detected." >&2
  echo "Command: $command" >&2
  echo "Confirm with the user before allowing a force push." >&2
  exit 2
fi

exit 0
