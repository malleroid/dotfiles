#!/usr/bin/env fish
# MCPM Client Configuration Script
# This script configures MCP servers for Claude Code, Claude Desktop, and Codex CLI

echo "Configuring MCP clients with mcpm servers..."

# List of servers to configure
set servers "serena,playwright-mcp,chrome-devtools-mcp,rails-mcp-server"

# Configure Claude Code
echo "Configuring Claude Code..."
mcpm client edit claude-code --set-servers $servers --force

# Configure Claude Desktop
echo "Configuring Claude Desktop..."
mcpm client edit claude-desktop --set-servers $servers --force

# Configure Codex CLI
echo "Configuring Codex CLI..."
mcpm client edit codex-cli --set-servers $servers --force

echo ""
echo "✅ Configuration complete!"
echo ""
echo "Configured clients:"
mcpm client ls

echo ""
echo "⚠️  Remember to restart each client for changes to take effect:"
echo "  - Claude Code: Restart the CLI session"
echo "  - Claude Desktop: Restart the application"
echo "  - Codex CLI: Restart codex sessions"
