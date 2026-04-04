# Claude Code Plugins

Plugins are installed interactively inside Claude Code sessions.
They cannot be automated via shell scripts.

## codex-plugin-cc

OpenAI Codex integration for Claude Code. Provides cross-model code review and background task delegation.

Repository: https://github.com/openai/codex-plugin-cc

### Prerequisites

- Codex CLI installed and authenticated (`codex login`)

### Installation

Run inside a Claude Code session:

```
/plugin marketplace add openai/codex-plugin-cc
/plugin install codex@openai-codex
/reload-plugins
/codex:setup
```

### Commands

| Command | Purpose |
|---------|---------|
| `/codex:review` | Code review on uncommitted changes or branch diffs |
| `/codex:adversarial-review` | Pressure-test design decisions and assumptions |
| `/codex:rescue` | Delegate tasks to Codex as background jobs |
| `/codex:status` | Show running and recent Codex jobs |
| `/codex:result` | Show output from completed jobs |
| `/codex:cancel` | Terminate active background tasks |

### Configuration

Codex CLI config is managed by chezmoi (`dot_codex/config.toml`, `dot_codex/AGENTS.md`).
Plugin files under `~/.claude/plugins/` are runtime cache and should not be version-controlled.
