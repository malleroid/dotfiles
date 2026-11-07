#!/usr/bin/env bash
# SessionStart hook: show how many items of the private "Agent Queue" project
# target the current repository and wait on the agent or the user, and archive
# items that have been Done for a while once a day. Stays silent on any failure.
#
# Counts are cached for the day, one line per repository, in a single file that
# keeps only today's lines. agent-queue deletes it whenever an item changes.

LIB="$HOME/.local/lib/gh-project.sh"
QUEUE="$HOME/.local/bin/agent-queue"
[ -f "$LIB" ] && [ -x "$QUEUE" ] || exit 0
# shellcheck source=/dev/null
source "$LIB"

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/agent-queue"
CACHE="$STATE_DIR/cache"
PRUNED="$STATE_DIR/pruned"
TODAY="$(date +%F)"
REPO="$(ghp_current_repo)"

emit() {
  [ -n "$1" ] && jq -n --arg msg "$1" '{systemMessage: $msg}'
  exit 0
}

mkdir -p "$STATE_DIR" || exit 0

if [ "$(cat "$PRUNED" 2>/dev/null)" != "$TODAY" ]; then
  echo "$TODAY" >"$PRUNED"
  ("$QUEUE" prune >/dev/null 2>&1 &)
fi

if [ -f "$CACHE" ]; then
  while IFS=$'\t' read -r day repo msg; do
    if [ "$day" = "$TODAY" ] && [ "$repo" = "$REPO" ]; then
      emit "$msg"
    fi
  done <"$CACHE"
fi

items="$("$QUEUE" list --here 2>/dev/null)" || exit 0
counts="$(jq -r '
  [("To Do", "Needs Decision", "Needs Go-ahead") as $s
    | {s: $s, n: ([.[] | select(.status == $s)] | length)}
    | select(.n > 0)
    | "\(.s) \(.n)"]
  | join(", ")' <<<"$items" 2>/dev/null)" || exit 0

msg=""
[ -n "$counts" ] && msg="Agent queue ($REPO): $counts. Use the agent-queue skill to pick one up."

{
  grep -v -F "$TODAY"$'\t'"$REPO"$'\t' "$CACHE" 2>/dev/null | grep "^$TODAY"$'\t'
  printf '%s\t%s\t%s\n' "$TODAY" "$REPO" "$msg"
} >"$CACHE.tmp" && mv "$CACHE.tmp" "$CACHE"
emit "$msg"
