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
    "feature-dev@claude-plugins-official"

for plugin in $plugins
    claude plugin install $plugin --scope user 2>/dev/null
    and echo "  ✅ $plugin"
    or echo "  ⏭️  $plugin (already installed)"
end

echo ""
echo "✅ Claude Code setup complete!"
echo "⚠️  Restart Claude Code for changes to take effect."
