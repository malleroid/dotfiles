# Agent feedback inbox

Raw feedback cases from agent sessions (a rejected tool call, a change of
direction, an approved non-obvious approach) are recorded in a private GitHub
Project instead of being written into `CLAUDE.md` as rules right away. Cases are
promoted to rules or mechanisms only through `/feedback-review`, with the user's
approval.

The cases quote the user and describe work in other repositories, so they stay
out of this public repository. Only the abstracted rules that get promoted are
written here.

## Flow

1. **Record**: when a signal is detected, the agent shows a draft and, once
   approved, records it with `feedback-record` (rule in `dot_claude/CLAUDE.md`).
2. **Remind**: the SessionStart hook `dot_claude/hooks/executable_feedback_inbox_reminder.sh`
   shows a message when the inbox holds 15 or more cases, or when the oldest
   case is 30 days old or more. The result is cached for the day in
   `~/.local/state/feedback-inbox/cache`.
3. **Review**: `/feedback-review` (`dot_agents/skills/feedback-review/SKILL.md`)
   groups the cases, proposes what to promote and where, and applies only what
   the user approves. Reviewed cases get a final Status and are archived.

## Project

- Owner: the user (`@me`), private
- Title: `Agent Feedback Inbox` (the scripts look the project up by this title)
- Items: draft issues only. Do not add issues from public repositories; they
  stay public even inside a private project.

### Fields

| Field | Type | Options | Set by |
|---|---|---|---|
| Status | single select (built-in) | `Inbox`, `Adopted`, `Rejected` | `feedback-record` (`Inbox`), `/feedback-review` |
| Signal | single select | `rejected`, `redirect`, `approved` | `feedback-record` |
| Source Repo | text | | `feedback-record`, from the git remote (`owner/repo`) or the directory name |
| Host | text | | `feedback-record`, from `hostname -s` |
| Destination | single select | `hook`, `lint`, `skill`, `CLAUDE.md`, `memory` | `/feedback-review` when a case is adopted |

`Repo` is a reserved field name in GitHub Projects, hence `Source Repo`.

The scripts and the hook look fields and options up by these names. Renaming
one breaks them until they are updated too.

### Changing options

Changing options in the GitHub UI is safe. When changing them through the
GraphQL `updateProjectV2Field` mutation, pass the `id` of every option that is
kept: the mutation replaces the whole option list, and items whose option has
no `id` lose their value.

### Recreating the project

The project was created by `scripts/setup-feedback-project.sh`, removed after
setup. Restore it from commit `ca0f1b5` if the project ever needs to be
recreated.

## Commands

Deployed to `~/.local/bin` from `dot_local/bin/`. All of them use `gh` (token
with the `project` scope) and `jq`.

| Command | Purpose |
|---|---|
| `feedback-record <rejected\|redirect\|approved> <title> < body` | Record one case with Status `Inbox` |
| `feedback-list [Inbox\|Adopted\|Rejected\|all]` | Print non-archived cases as JSON (default `Inbox`) |
| `feedback-update <PVTI_id> [--title] [--body-stdin] [--status] [--destination] [--archive]` | Update one case. Changing Status or archiving drops the reminder cache |

The reminder thresholds can be overridden with `FEEDBACK_INBOX_MIN_COUNT` and
`FEEDBACK_INBOX_MAX_AGE_DAYS`.
