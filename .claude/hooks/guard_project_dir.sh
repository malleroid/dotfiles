#!/usr/bin/env bash
# Block file operations outside CLAUDE_PROJECT_DIR

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

[ -z "$CLAUDE_PROJECT_DIR" ] && exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR%/}"

# Get file path(s) — MultiEdit has an edits array
if [ "$TOOL_NAME" = "MultiEdit" ]; then
  FILE_PATHS=$(echo "$INPUT" | jq -r '.tool_input.edits[].file_path // empty')
else
  FILE_PATHS=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
fi

[ -z "$FILE_PATHS" ] && exit 0

while IFS= read -r FILE_PATH; do
  [ -z "$FILE_PATH" ] && continue

  # Resolve relative path against project dir
  if [[ "$FILE_PATH" != /* ]]; then
    FILE_PATH="${PROJECT_DIR}/${FILE_PATH}"
  fi

  if [[ "$FILE_PATH" != "$PROJECT_DIR/"* && "$FILE_PATH" != "$PROJECT_DIR" ]]; then
    echo "🚫 Blocked: File operation outside project directory" >&2
    echo "File: $FILE_PATH" >&2
    echo "Project: $PROJECT_DIR" >&2
    echo "Per CLAUDE.md security rules, file operations are restricted to the current repository." >&2
    exit 2
  fi
done <<< "$FILE_PATHS"

exit 0
