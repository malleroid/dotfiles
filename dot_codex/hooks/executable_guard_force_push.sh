#!/usr/bin/env bash
set -euo pipefail

input=$(cat)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

[ -z "$command" ] && exit 0

if printf '%s\n' "$command" | grep -qE 'git[[:space:]]+push[[:space:]].*(-f([[:space:]]|$)|--force([[:space:]]|$))'; then
  if [ "${CODEX_CONFIRM_DANGEROUS_COMMAND:-}" = "1" ]; then
    exit 0
  fi

  echo "Blocked: force push detected." >&2
  echo "Command: $command" >&2
  echo "After user approval, rerun with CODEX_CONFIRM_DANGEROUS_COMMAND=1." >&2
  exit 2
fi

exit 0
