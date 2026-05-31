#!/usr/bin/env sh
set -eu

input=$(cat)

jq_get() {
  printf %s "$input" | jq -r "$1" 2>/dev/null || true
}

command=$(jq_get '.toolArgs.command // .toolArgs.cmd // .tool_input.command // .tool_input.cmd // empty')
[ -n "$command" ] || exit 0

deny() {
  jq -nc --arg reason "$1" '{permissionDecision:"deny", permissionDecisionReason:$reason}'
  exit 0
}

ask() {
  jq -nc --arg reason "$1" '{permissionDecision:"ask", permissionDecisionReason:$reason}'
  exit 0
}

case "$command" in
  *"git -C "*|*"git -C"*)
    deny "git -C is prohibited. Run git commands from the target working directory instead."
    ;;
esac

if printf '%s\n' "$command" | grep -qE '(^|[[:space:]])gh[[:space:]]+pr[[:space:]]+merge([[:space:]]|$)'; then
  deny "gh pr merge is prohibited. Merge pull requests outside Copilot, or change this guard intentionally."
fi

if printf '%s\n' "$command" | grep -qE '(^|[[:space:]])git[[:space:]]+push[[:space:]].*(-f([[:space:]]|$)|--force([[:space:]]|$))'; then
  ask "Force push detected. Proceed only after explicit user approval."
fi

requires_confirmation='(^|[[:space:]])gh[[:space:]]+api[[:space:]].*(--method|-X)[[:space:]]*(DELETE|PATCH|POST|PUT)([[:space:]]|$)|(^|[[:space:]])gh[[:space:]]+pr[[:space:]]+create([[:space:]]|$)|(^|[[:space:]])gh[[:space:]]+release[[:space:]]+(create|delete|upload)([[:space:]]|$)|(^|[[:space:]])gh[[:space:]]+repo[[:space:]]+(archive|delete|rename|transfer|unarchive)([[:space:]]|$)|(^|[[:space:]])gh[[:space:]]+run[[:space:]]+rerun([[:space:]]|$)|(^|[[:space:]])gh[[:space:]]+secret[[:space:]]+(delete|set)([[:space:]]|$)|(^|[[:space:]])gh[[:space:]]+variable[[:space:]]+(delete|set)([[:space:]]|$)|(^|[[:space:]])gh[[:space:]]+workflow[[:space:]]+(disable|enable|run)([[:space:]]|$)|(^|[[:space:]])git[[:space:]]+commit[[:space:]].*--amend|(^|[[:space:]])git[[:space:]]+commit[[:space:]].*--allow-empty|(^|[[:space:]])git[[:space:]]+commit[[:space:]].*--no-verify|(^|[[:space:]])git[[:space:]]+push([[:space:]]|$)|(^|[[:space:]])git[[:space:]]+reset([[:space:]]|$)'

if printf '%s\n' "$command" | grep -qE "$requires_confirmation"; then
  ask "This command mutates repository, GitHub, release, workflow, secret, or variable state. Confirm before running."
fi

exit 0
