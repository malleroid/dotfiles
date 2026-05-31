#!/usr/bin/env sh
set -eu

input=$(cat)

jq_get() {
  printf %s "$input" | jq -r "$1" 2>/dev/null || true
}

cwd=$(jq_get ' .workspace.current_dir // .workspace.currentDirectory // .cwd // .current_dir // .currentDirectory // .session.cwd // empty ')
[ -n "$cwd" ] || cwd=$(pwd -P)

case "$cwd" in
  "$HOME")
    cwd_display="~"
    ;;
  "$HOME"/*)
    cwd_display="~/${cwd#"$HOME"/}"
    ;;
  *)
    cwd_display="$cwd"
    ;;
esac

ctx=$(jq_get ' .context_window.used_percentage // .contextWindow.usedPercentage // .context.used_percentage // .context.usedPercentage // .usage.context_window.used_percentage // .usage.contextWindow.usedPercentage // empty ')
[ -n "$ctx" ] || ctx="-"

branch=$(
  cd "$cwd" 2>/dev/null &&
    git --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null
) || branch=""

if [ -n "$branch" ]; then
  printf '%s  %s  ctx:%s%%' "$cwd_display" "$branch" "$ctx"
else
  printf '%s  ctx:%s%%' "$cwd_display" "$ctx"
fi
