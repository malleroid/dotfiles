# Helpers shared by the scripts that work on private GitHub Projects owned by
# the user (Agent Queue, Agent Feedback Inbox). Source this file; it defines
# functions only. Requires gh (token with the project scope) and jq.

# Print the number of the user's project with this title.
ghp_project_number() {
  local title="$1" number
  if ! number="$(gh project list --owner "@me" --format json --limit 200 \
    --jq ".projects[] | select(.title == \"$title\") | .number")"; then
    echo "error: gh cannot list projects (the token needs the project scope: gh auth refresh -s project)" >&2
    return 1
  fi
  if [ -z "$number" ]; then
    echo "error: project not found: $title" >&2
    return 1
  fi
  echo "$number"
}

ghp_project_id() {
  gh project view "$1" --owner "@me" --format json --jq .id
}

# Load the field list of a project into GHP_FIELDS for ghp_field_id / ghp_option_id.
ghp_load_fields() {
  GHP_FIELDS="$(gh project field-list "$1" --owner "@me" --format json --limit 50)"
}

ghp_field_id() {
  jq -er --arg n "$1" '.fields[] | select(.name == $n) | .id' <<<"$GHP_FIELDS"
}

ghp_option_id() {
  jq -er --arg n "$1" --arg o "$2" \
    '.fields[] | select(.name == $n) | .options[] | select(.name == $o) | .id' <<<"$GHP_FIELDS"
}

# Print the current repository as owner/repo from the origin remote, falling
# back to the name of the top-level directory (or the current directory).
ghp_current_repo() {
  local remote
  remote="$(git remote get-url origin 2>/dev/null || true)"
  if [ -n "$remote" ]; then
    sed -E 's#^(git@[^:]+:|[a-z]+://[^/]+/)##; s#\.git$##' <<<"$remote"
  else
    basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  fi
}
