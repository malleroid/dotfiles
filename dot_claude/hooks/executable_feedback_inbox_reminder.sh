#!/usr/bin/env bash
# SessionStart hook: remind the user to run /feedback-review when the private
# "Agent Feedback Inbox" project has piled up. Stays silent on any failure.
#
# The result is cached for the day in a single file that is overwritten on each
# refresh, so nothing accumulates. /feedback-review deletes it after a review.

PROJECT_TITLE="Agent Feedback Inbox"
MIN_COUNT="${FEEDBACK_INBOX_MIN_COUNT:-15}"
MAX_AGE_DAYS="${FEEDBACK_INBOX_MAX_AGE_DAYS:-30}"

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/feedback-inbox"
CACHE="$STATE_DIR/cache"
TODAY="$(date +%F)"

emit() {
  [ -n "$1" ] && jq -n --arg msg "$1" '{systemMessage: $msg}'
  exit 0
}

# A line without its trailing newline (interrupted write) fails `read` and counts as a miss.
if [ -f "$CACHE" ] && IFS=$'\t' read -r day msg <"$CACHE" && [ "$day" = "$TODAY" ]; then
  emit "$msg"
fi

number="$(gh project list --owner "@me" --format json --limit 200 \
  --jq ".projects[] | select(.title == \"$PROJECT_TITLE\") | .number" 2>/dev/null)" || exit 0
[ -n "$number" ] || exit 0

summary="$(gh api graphql -F number="$number" -f query='
  query($number: Int!) {
    viewer {
      projectV2(number: $number) {
        items(first: 100) {
          nodes {
            createdAt
            isArchived
            status: fieldValueByName(name: "Status") {
              ... on ProjectV2ItemFieldSingleSelectValue { name }
            }
          }
        }
      }
    }
  }' --jq '
  [.data.viewer.projectV2.items.nodes[] | select(.isArchived | not) | select(.status.name == "Inbox")]
  | {count: length, age: (if length == 0 then 0 else ((now - (map(.createdAt | fromdateiso8601) | min)) / 86400 | floor) end)}
  ' 2>/dev/null)" || exit 0

count="$(jq -r .count <<<"$summary")"
age="$(jq -r .age <<<"$summary")"

msg=""
if [ "$count" -ge "$MIN_COUNT" ] || { [ "$count" -gt 0 ] && [ "$age" -ge "$MAX_AGE_DAYS" ]; }; then
  msg="Feedback inbox: $count case(s), oldest ${age}d old. Run /feedback-review."
fi

mkdir -p "$STATE_DIR" && printf '%s\t%s\n' "$TODAY" "$msg" >"$CACHE"
emit "$msg"
