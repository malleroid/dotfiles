#!/usr/bin/env fish
# MCP Server Setup Script
# Configures both mcpm-managed (stdio) and remote (SSE) servers for all clients

# ── 1. mcpm-managed servers (stdio) ──
set mcpm_servers "serena,playwright-mcp,chrome-devtools-mcp,rails-mcp-server,awslabs.aws-documentation-mcp-server"

echo "=== mcpm servers (stdio) ==="
echo "Configuring Claude Code..."
mcpm client edit claude-code --set-servers $mcpm_servers --force

echo "Configuring Claude Desktop..."
mcpm client edit claude-desktop --set-servers $mcpm_servers --force

echo "Configuring Codex CLI..."
mcpm client edit codex-cli --set-servers $mcpm_servers --force

# ── 2. Remote MCP servers (Claude Code only) ──
# mcpm run proxy does not support OAuth flow, so remote servers are configured directly.
# NOTE: Claude Desktop is intentionally excluded from remote server configuration.
echo ""
echo "=== Remote MCP servers (SSE) ==="

set script_dir (status dirname)
set remote_config "$script_dir/remote-servers.json"
set claude_code_config "$HOME/.claude.json"

if not test -f "$remote_config"
    echo "  ⏭️  No remote-servers.json found, skipping"
else
    # Claude Code: use official CLI
    for name in (jq -r 'keys[]' "$remote_config")
        set url (jq -r --arg n "$name" '.[$n].url' "$remote_config")
        set transport (jq -r --arg n "$name" '.[$n].transport' "$remote_config")
        claude mcp add --transport $transport $name $url --scope user 2>/dev/null
        and echo "  ✅ Claude Code: $name"
        or echo "  ⏭️  Claude Code: $name (already exists)"
    end

end

echo ""
echo "✅ Setup complete!"
echo ""
echo "⚠️  Remember to restart each client for changes to take effect."
echo "📋 Remote servers (OAuth): Run /mcp in each client to authenticate on first use."
