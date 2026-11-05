#!/usr/bin/env bash
set -euo pipefail

# Create or reconcile the private GitHub Project that collects agent feedback cases.
# Safe to re-run: missing fields are created and single-select options are reconciled
# to the spec below (options missing from the spec are removed).
#
# Usage:
#   scripts/setup-feedback-project.sh
#
# Requires gh (token with the project scope) and jq.

title="Agent Feedback Inbox"

spec='[
  {"name": "Status", "type": "SINGLE_SELECT", "options": [
    {"name": "Inbox",    "color": "GRAY",  "description": "Recorded, not reviewed yet"},
    {"name": "Adopted",  "color": "GREEN", "description": "Promoted to a rule or mechanism"},
    {"name": "Rejected", "color": "RED",   "description": "Reviewed and discarded"}
  ]},
  {"name": "Signal", "type": "SINGLE_SELECT", "options": [
    {"name": "rejected", "color": "RED",    "description": "User rejected a tool call"},
    {"name": "redirect", "color": "YELLOW", "description": "User changed direction"},
    {"name": "approved", "color": "GREEN",  "description": "User approved a non-obvious approach"}
  ]},
  {"name": "Source Repo", "type": "TEXT"},
  {"name": "Host", "type": "TEXT"},
  {"name": "Destination", "type": "SINGLE_SELECT", "options": [
    {"name": "hook",      "color": "PURPLE", "description": "Enforced by a hook"},
    {"name": "lint",      "color": "BLUE",   "description": "Enforced by a lint rule"},
    {"name": "skill",     "color": "ORANGE", "description": "Written into a skill"},
    {"name": "CLAUDE.md", "color": "PINK",   "description": "Written into a CLAUDE.md"},
    {"name": "memory",    "color": "GRAY",   "description": "Saved to project auto memory"}
  ]}
]'

fetch_fields() {
  gh api graphql -F number="$number" -f query='
    query($number: Int!) {
      viewer {
        projectV2(number: $number) {
          fields(first: 50) {
            nodes {
              ... on ProjectV2Field { id name dataType }
              ... on ProjectV2SingleSelectField {
                id name dataType
                options { id name color description }
              }
            }
          }
        }
      }
    }' --jq '.data.viewer.projectV2.fields.nodes'
}

reconcile_options() {
  local field="$1" want="$2" have="$3"

  if jq -e -n --argjson want "$want" --argjson have "$have" \
    '($have.options | map({name, color, description})) == ($want | map({name, color, description}))' >/dev/null; then
    return
  fi

  local dropped
  dropped="$(jq -r -n --argjson want "$want" --argjson have "$have" \
    '[$have.options[].name] - [$want[].name] | join(", ")')"
  echo "==> Reconciling options of $(jq -r .name <<<"$have")"
  if [ -n "$dropped" ]; then
    echo "    removing: $dropped (items holding these values lose them)"
  fi

  jq -n --arg id "$field" --argjson want "$want" --argjson have "$have" '{
    query: "mutation($id: ID!, $opts: [ProjectV2SingleSelectFieldOptionInput!]) { updateProjectV2Field(input: {fieldId: $id, singleSelectOptions: $opts}) { projectV2Field { ... on ProjectV2SingleSelectField { id } } } }",
    variables: {
      id: $id,
      opts: [$want[] | . as $o | {name, color, description} + ([$have.options[] | select(.name == $o.name) | {id}] | first // {})]
    }
  }' | gh api graphql --input - >/dev/null
}

number="$(gh project list --owner "@me" --format json --limit 200 \
  --jq ".projects[] | select(.title == \"$title\") | .number")"

if [ -z "$number" ]; then
  echo "==> Creating project: $title"
  number="$(gh project create --owner "@me" --title "$title" --format json --jq .number)"
fi

echo "==> Ensuring project #$number is private"
gh project edit "$number" --owner "@me" --visibility PRIVATE >/dev/null

current="$(fetch_fields)"

while IFS= read -r field; do
  name="$(jq -r .name <<<"$field")"
  type="$(jq -r .type <<<"$field")"
  existing="$(jq -c --arg n "$name" '.[] | select(.name == $n)' <<<"$current")"

  if [ -z "$existing" ]; then
    echo "==> Creating field: $name ($type)"
    args=(--owner "@me" --name "$name" --data-type "$type")
    if [ "$type" = "SINGLE_SELECT" ]; then
      args+=(--single-select-options "$(jq -r '[.options[].name] | join(",")' <<<"$field")")
    fi
    gh project field-create "$number" "${args[@]}" >/dev/null
    current="$(fetch_fields)"
    existing="$(jq -c --arg n "$name" '.[] | select(.name == $n)' <<<"$current")"
  fi

  actual_type="$(jq -r .dataType <<<"$existing")"
  if [ "$actual_type" != "$type" ]; then
    echo "!! Field $name exists as $actual_type, expected $type. Fix it by hand." >&2
    exit 1
  fi

  if [ "$type" = "SINGLE_SELECT" ]; then
    reconcile_options "$(jq -r .id <<<"$existing")" "$(jq -c .options <<<"$field")" "$existing"
  fi
done < <(jq -c '.[]' <<<"$spec")

echo "==> Done: $(gh project view "$number" --owner "@me" --format json --jq .url)"
