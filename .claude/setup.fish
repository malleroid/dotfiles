#!/usr/bin/env fish
# Claude Code Setup Script
# Run from a separate terminal (not inside a Claude Code session)

echo "=== Claude Code Setup ==="

# ── Marketplaces ──
echo ""
echo "Registering plugin marketplaces..."

set marketplaces \
    "anthropics/claude-plugins-official"

for marketplace in $marketplaces
    claude plugin marketplace add $marketplace 2>/dev/null
    and echo "  ✅ $marketplace"
    or echo "  ⏭️  $marketplace (already registered)"
end

# ── Plugins ──
echo ""
echo "Installing plugins..."

set plugins \
    "commit-commands@claude-plugins-official" \
    "claude-md-management@claude-plugins-official" \
    "feature-dev@claude-plugins-official" \
    "slack@claude-plugins-official"

for plugin in $plugins
    claude plugin install $plugin --scope user 2>/dev/null
    and echo "  ✅ $plugin"
    or echo "  ⏭️  $plugin (already installed)"
end

# ── MCP Servers (requires auth — register manually) ──
echo ""
echo "Manual steps required for authenticated MCP servers:"
echo "  context7:"
echo "    1. Get API key at https://context7.com/dashboard"
echo "    2. Run: claude mcp add --scope user context7 context7-mcp"
echo "    3. Edit ~/.claude.json and add CONTEXT7_API_KEY to context7.env"
echo "  slack:"
echo "    1. Ensure Slack workspace admin has approved MCP integration"
echo "    2. Run Claude Code and complete OAuth flow via browser"

echo ""
echo "✅ Claude Code setup complete!"
echo "⚠️  Restart Claude Code for changes to take effect."
