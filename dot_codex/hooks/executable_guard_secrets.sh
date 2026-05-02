#!/usr/bin/env bash
set -euo pipefail

input=$(cat)
tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty')
patch=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

[ "$tool_name" = "apply_patch" ] || exit 0
[ -n "$patch" ] || exit 0

paths=$(
  printf '%s\n' "$patch" | sed -n -E 's/^\*\*\* (Add|Update|Delete) File: (.+)$/\2/p'
)

[ -n "$paths" ] || exit 0

patterns=(
  '\.pem$'
  '\.key$'
  '\.env$'
  '\.env\.'
  'credentials\.yml\.enc$'
  '(^|/)\.?secrets\.(json|ya?ml|env|txt|csv|toml|ini|cfg|conf|properties)$'
  '\.p12$'
  '(^|/)id_rsa'
  '(^|/)id_ed25519'
)

while IFS= read -r path; do
  [ -z "$path" ] && continue
  for pattern in "${patterns[@]}"; do
    if printf '%s\n' "$path" | grep -qE "$pattern"; then
      echo "Blocked: sensitive file detected." >&2
      echo "Path: $path" >&2
      echo "Matched pattern: $pattern" >&2
      exit 2
    fi
  done
done <<< "$paths"

exit 0
