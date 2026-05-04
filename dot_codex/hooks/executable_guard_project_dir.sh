#!/usr/bin/env bash
set -euo pipefail

input=$(cat)
tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty')

project_dir=$(printf '%s' "$input" | jq -r '
  .cwd //
  .workdir //
  .workspace.current_dir //
  .workspace_root //
  empty
')

[ -n "$project_dir" ] || project_dir=$(pwd -P)

normalize_path() {
  local path="$1"
  local -a parts normalized
  local part

  if [[ "$path" != /* ]]; then
    path="${project_dir%/}/$path"
  fi

  IFS='/' read -r -a parts <<< "$path"
  normalized=()
  for part in "${parts[@]}"; do
    case "$part" in
      ""|".")
        ;;
      "..")
        if [ "${#normalized[@]}" -gt 0 ]; then
          unset 'normalized[${#normalized[@]}-1]'
        fi
        ;;
      *)
        normalized+=("$part")
        ;;
    esac
  done

  printf '/%s\n' "$(IFS=/; printf '%s' "${normalized[*]}")"
}

project_dir=$(normalize_path "$project_dir")

paths=$(
  if [ "$tool_name" = "apply_patch" ]; then
    patch=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
    printf '%s\n' "$patch" | sed -n -E \
      -e 's/^\*\*\* (Add|Update|Delete) File: (.+)$/\2/p' \
      -e 's/^\*\*\* Move to: (.+)$/\1/p'
  fi

  printf '%s' "$input" | jq -r '
    .tool_input.file_path? // empty,
    .tool_input.path? // empty,
    .tool_input.edits[]?.file_path? // empty
  '
)

[ -n "$paths" ] || exit 0

while IFS= read -r path; do
  [ -n "$path" ] || continue

  normalized_path=$(normalize_path "$path")

  if [[ "$normalized_path" != "$project_dir" && "$normalized_path" != "$project_dir/"* ]]; then
    echo "Blocked: file operation outside project directory." >&2
    echo "Path: $path" >&2
    echo "Resolved path: $normalized_path" >&2
    echo "Project: $project_dir" >&2
    exit 2
  fi
done <<< "$paths"

exit 0
