#!/usr/bin/env bash
# Block writes to sensitive/secret files per CLAUDE.md forbidden patterns

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Get file path(s) — MultiEdit has an edits array
if [ "$TOOL_NAME" = "MultiEdit" ]; then
  FILE_PATHS=$(echo "$INPUT" | jq -r '.tool_input.edits[].file_path // empty')
else
  FILE_PATHS=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
fi

[ -z "$FILE_PATHS" ] && exit 0

# Forbidden patterns from CLAUDE.md
# Note: 'secrets' glob is scoped to data file extensions to avoid matching code files (e.g. guard_secrets.sh)
PATTERNS=(
  '\.pem$'
  '\.key$'
  '\.env$'
  '\.env\.'
  'credentials\.yml\.enc'
  '(^|/)\.?secrets\.(json|ya?ml|env|txt|csv|toml|ini|cfg|conf|properties)$'
  '\.p12$'
  '/id_rsa'
  '/id_ed25519'
)

while IFS= read -r FILE_PATH; do
  [ -z "$FILE_PATH" ] && continue
  for pattern in "${PATTERNS[@]}"; do
    if echo "$FILE_PATH" | grep -qE "$pattern"; then
      echo "🚫 Blocked: Sensitive file detected" >&2
      echo "File: $FILE_PATH" >&2
      echo "Matched pattern: $pattern" >&2
      echo "Per CLAUDE.md security rules, writing to this file is blocked." >&2
      exit 2
    fi
  done
done <<< "$FILE_PATHS"

exit 0
