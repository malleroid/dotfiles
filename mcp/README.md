# MCP servers

Run `fish mcp/setup.fish` to register the servers below with each client.

| File | Contents |
|------|----------|
| `servers.json` | stdio servers |
| `local-servers.json` | local HTTP servers |
| `remote-servers.json` | remote HTTP/SSE servers |

## Adding a server

Copilot and Codex configs are also managed by chezmoi, which overwrites whatever `setup.fish` writes there.
Keep these three in sync:

- `mcp/servers.json` (or the local/remote variant)
- `dot_copilot/mcp-config.json`
- `dot_codex/modify_private_config.toml`

To skip a client for a stdio server, add `"exclude_clients"` to its entry (`desktop`, `copilot`, `codex`).

## Environment variables

Secrets are not stored in config; servers read them from the environment of the client that launches them.

| Client | Behavior |
|--------|----------|
| Claude Code | Inherits the launching shell's environment |
| Codex | Passes only a default allowlist (HOME, PATH, ...); list extra names in `env_vars` |
| Copilot | Not documented; pass explicitly via `env` with `${VAR}` expansion |
| Claude Desktop | GUI app, does not see shell variables |

## grafana

[mcp-grafana](https://github.com/grafana/mcp-grafana) (installed via Nix). Works with Amazon Managed Grafana using a service account token (max TTL 30 days).
Not registered with Claude Desktop.

Set the variables before starting the client:

```fish
set -x GRAFANA_URL https://g-xxxx.grafana-workspace.<region>.amazonaws.com
set -x GRAFANA_SERVICE_ACCOUNT_TOKEN glsa_xxxx
claude
```

If they are unset, only the grafana server fails to connect.
