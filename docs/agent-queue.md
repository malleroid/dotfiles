# Agent queue

Work to hand to coding agents, including ideas that are not sorted out yet,
is queued in one private GitHub Project instead of in each repository. A
session can start in any repository and only sees the items that target it.

Daily personal tasks and the requirements of work tickets live elsewhere
(Obsidian Tasks and Jira). Items for work repositories carry only the Jira key
and a minimal note.

## Flow

1. **Queue**: the `agent-queue` skill (`dot_agents/skills/agent-queue/SKILL.md`)
   adds an item after showing it to the user. Ideas without a target repository
   go to `Inbox` with no `Target Repo`.
2. **Remind**: the SessionStart hook `dot_claude/hooks/executable_agent_queue_reminder.sh`
   shows the counts of `To Do`, `Needs Decision` and `Needs Go-ahead` items that
   target the current repository. Counts are cached for the day per repository
   in `~/.local/state/agent-queue/cache`; `agent-queue` drops the cache on every
   change.
3. **Work**: the skill picks one `To Do` item, claims it, logs progress into the
   body, and stops at `Needs Go-ahead` before anything leaves the machine.
4. **Archive**: once a day the hook runs `agent-queue prune` in the background,
   archiving items that have been `Done` for 14 days or more. The project's
   built-in auto-archive workflow cannot be used: its filter rejects `status:`
   and draft issues are never closed.

## Project

- Owner: the user (`@me`), private
- Title: `Agent Queue` (the scripts look the project up by this title)
- Items: draft issues only. Issues would have to live in a repository, and
  public repositories would expose them even inside a private project.
- Created by `scripts/setup-agent-queue-project.sh`, which is safe to re-run

### Fields

| Field | Type | Values | Set by |
|---|---|---|---|
| Status | single select (built-in) | `Inbox`, `To Do`, `In Progress`, `Needs Decision`, `Needs Go-ahead`, `Waiting`, `Done` | `agent-queue` |
| Target Repo | text | `owner/repo`; empty when undecided | `add`, `edit` |
| Jira | text | issue key | `add`, `edit` |
| Claimed By | text | `hostname -s` of the claiming machine | `claim`; cleared when moved back to `Inbox` or `To Do` |

`Repo` is a reserved field name in GitHub Projects, hence `Target Repo`.

Status is chosen by who acts next: the agent (`To Do`, `In Progress`), the
user (`Needs Decision`, `Needs Go-ahead`), someone else (`Waiting`), or nobody
(`Inbox`, `Done`).

The project's "Item added to project" workflow sets Status to `Inbox`, so
items added from the GitHub UI land there too.

## Commands

Deployed to `~/.local/bin` from `dot_local/bin/`, sharing helpers in
`dot_local/lib/gh-project.sh`. They use `gh` (token with the `project` scope)
and `jq`, so they work only where that token is available; cloud sessions are
not set up for it.

| Command | Purpose |
|---|---|
| `agent-queue add <title> [--here \| --repo owner/repo \| --none] [--status S] [--jira KEY] < body` | Add an item (default: current repository, `Inbox`) |
| `agent-queue list [--here \| --repo owner/repo \| --unscoped \| --all] [--open \| --status S]` | Print items as JSON (default: current repository, not `Done`) |
| `agent-queue show <PVTI_id>` | Print one item with its body |
| `agent-queue claim <PVTI_id> [--force]` | Set `In Progress` and `Claimed By`; refuses an item another host is working on |
| `agent-queue note <PVTI_id> < text` | Append a dated entry to the body's work log |
| `agent-queue move <PVTI_id> <status>` | Change Status |
| `agent-queue edit <PVTI_id> [--title] [--body-stdin] [--here \| --repo \| --none] [--jira KEY \| --no-jira]` | Rewrite or re-target an item |
| `agent-queue done <PVTI_id> [--archive]` | Set `Done` |
| `agent-queue prune [--older-than DAYS]` | Archive items `Done` for DAYS or more (default 14) |
