#!/usr/bin/env sh
set -eu

input=$(cat)

jq_get() {
  printf %s "$input" | jq -r "$1" 2>/dev/null || true
}

cwd=$(jq_get '.cwd // .workspace.current_dir // .workspace.currentDirectory // empty')
[ -n "$cwd" ] || cwd=$(pwd -P)

paths=$(printf %s "$input" | jq -r '
  .toolArgs.filePath? // empty,
  .toolArgs.file_path? // empty,
  .toolArgs.path? // empty,
  .toolArgs.edits[]?.filePath? // empty,
  .toolArgs.edits[]?.file_path? // empty,
  .tool_input.file_path? // empty,
  .tool_input.filePath? // empty,
  .tool_input.path? // empty,
  .tool_input.edits[]?.file_path? // empty,
  .tool_input.edits[]?.filePath? // empty
' 2>/dev/null || true)

[ -n "$paths" ] || exit 0

deny() {
  jq -nc --arg reason "$1" '{permissionDecision:"deny", permissionDecisionReason:$reason}'
  exit 0
}

normalize_path() {
  path=$1
  case "$path" in
    /*) ;;
    *) path=${cwd%/}/$path ;;
  esac

  oldpwd=$(pwd -P)
  dir=$(dirname "$path")
  name=$(basename "$path")
  if cd "$dir" 2>/dev/null; then
    printf '%s/%s\n' "$(pwd -P)" "$name"
  else
    case "$dir" in
      /*) printf '%s/%s\n' "$dir" "$name" ;;
      *) printf '%s/%s\n' "${cwd%/}/$dir" "$name" ;;
    esac
  fi
  cd "$oldpwd" >/dev/null 2>&1 || true
}

project=$(normalize_path "$cwd")

printf '%s\n' "$paths" | while IFS= read -r path; do
  [ -n "$path" ] || continue
  resolved=$(normalize_path "$path")

  case "$resolved" in
    "$project"|"$project"/*) ;;
    *) deny "File operation outside the current repository is prohibited: $path" ;;
  esac

  case "$path" in
    *.pem|*.key|*.env|*.p12|*credentials.yml.enc*|*secrets*|*id_rsa*|*id_ed25519*)
      deny "Sensitive file path is prohibited: $path"
      ;;
    *.env.*)
      deny "Sensitive file path is prohibited: $path"
      ;;
  esac
done

exit 0
