#!/usr/bin/env bash
set -euo pipefail

input=$(cat)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

[ -n "$command" ] || exit 0

block() {
  local reason="$1"
  local guidance="$2"

  echo "Blocked: $reason" >&2
  echo "Command: $command" >&2
  echo "$guidance" >&2
  exit 2
}

if printf '%s\n' "$command" | grep -qE '(^|[[:space:]])gh[[:space:]]+pr[[:space:]]+merge([[:space:]]|$)'; then
  block "gh pr merge is prohibited." \
    "Merge pull requests outside Codex, or change this guard intentionally."
fi

requires_confirmation=(
  '(^|[[:space:]])gh[[:space:]]+api[[:space:]].*(--method|-X)[[:space:]]*(DELETE|PATCH|POST|PUT)([[:space:]]|$)'
  '(^|[[:space:]])gh[[:space:]]+pr[[:space:]]+create([[:space:]]|$)'
  '(^|[[:space:]])gh[[:space:]]+release[[:space:]]+(create|delete|upload)([[:space:]]|$)'
  '(^|[[:space:]])gh[[:space:]]+repo[[:space:]]+(archive|delete|rename|transfer|unarchive)([[:space:]]|$)'
  '(^|[[:space:]])gh[[:space:]]+run[[:space:]]+rerun([[:space:]]|$)'
  '(^|[[:space:]])gh[[:space:]]+secret[[:space:]]+(delete|set)([[:space:]]|$)'
  '(^|[[:space:]])gh[[:space:]]+variable[[:space:]]+(delete|set)([[:space:]]|$)'
  '(^|[[:space:]])gh[[:space:]]+workflow[[:space:]]+(disable|enable|run)([[:space:]]|$)'
  '(^|[[:space:]])git[[:space:]]+commit[[:space:]].*--amend'
  '(^|[[:space:]])git[[:space:]]+commit[[:space:]].*--allow-empty'
  '(^|[[:space:]])git[[:space:]]+commit[[:space:]].*--no-verify'
  '(^|[[:space:]])git[[:space:]]+push([[:space:]]|$)'
  '(^|[[:space:]])git[[:space:]]+reset([[:space:]]|$)'
)

for pattern in "${requires_confirmation[@]}"; do
  if printf '%s\n' "$command" | grep -qE "$pattern"; then
    if [ "${CODEX_CONFIRM_DANGEROUS_COMMAND:-}" = "1" ]; then
      exit 0
    fi

    block "command requires explicit confirmation." \
      "After user approval, rerun with CODEX_CONFIRM_DANGEROUS_COMMAND=1."
  fi
done

exit 0
