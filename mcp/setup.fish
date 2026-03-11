#!/usr/bin/env fish
# MCP Server Setup Script
# Configures stdio and remote servers for all clients

set script_dir (status dirname)
set servers_config "$script_dir/servers.json"
set remote_config "$script_dir/remote-servers.json"

# ── 1. stdio servers ──
echo "=== stdio MCP servers ==="

for name in (jq -r 'keys[]' "$servers_config")
    set cmd  (jq -r --arg n $name '.[$n].command' "$servers_config")
    set args (jq -r --arg n $name '.[$n].args[]'  "$servers_config")

    # Build env flags per client
    set env_flags_claude
    set env_flags_codex
    set env_flags_gemini
    for key in (jq -r --arg n $name '.[$n].env | keys[]' "$servers_config")
        set val (jq -r --arg n $name --arg k $key '.[$n].env[$k]' "$servers_config")
        set env_flags_claude $env_flags_claude -e "$key=$val"
        set env_flags_codex  $env_flags_codex  --env "$key=$val"
        set env_flags_gemini $env_flags_gemini -e "$key=$val"
    end

    echo ""
    echo "  [$name]"

    # Claude Code (remove + add for upsert)
    # NOTE: name must come before -e flags to avoid -e consuming it as a variadic env value
    claude mcp remove --scope user $name 2>/dev/null
    claude mcp add --scope user $name $env_flags_claude -- $cmd $args 2>/dev/null
    and echo "  ✅ Claude Code"
    or  echo "  ❌ Claude Code (failed)"

    # Claude Desktop
    set desktop_cfg "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
    if test -f "$desktop_cfg"
        set entry (jq -c --arg n $name \
            '{command: .[$n].command, args: .[$n].args, env: .[$n].env}' \
            "$servers_config")
        jq --arg n $name --argjson e $entry '.mcpServers[$n] = $e' "$desktop_cfg" \
            > "$script_dir/_tmp_desktop.json"
        and mv "$script_dir/_tmp_desktop.json" "$desktop_cfg"
        and echo "  ✅ Claude Desktop"
        or  echo "  ❌ Claude Desktop (failed to update)"
    else
        echo "  ⏭️  Claude Desktop (config not found)"
    end

    # Copilot CLI
    set copilot_cfg "$HOME/.copilot/mcp-config.json"
    if not test -f "$copilot_cfg"
        mkdir -p ~/.copilot
        echo '{"mcpServers":{}}' > "$copilot_cfg"
    end
    set entry (jq -c --arg n $name \
        '{command: .[$n].command, args: .[$n].args, env: .[$n].env}' \
        "$servers_config")
    jq --arg n $name --argjson e $entry '.mcpServers[$n] = $e' "$copilot_cfg" \
        > "$script_dir/_tmp_copilot.json"
    and mv "$script_dir/_tmp_copilot.json" "$copilot_cfg"
    and echo "  ✅ Copilot"
    or  echo "  ❌ Copilot (failed)"

    # Codex CLI (writes through symlink to dotfiles/codex/config.toml)
    codex mcp add $env_flags_codex $name -- $cmd $args 2>/dev/null
    and echo "  ✅ Codex"
    or  echo "  ⏭️  Codex (already exists or error)"

    # Gemini CLI
    # NOTE: server args starting with '--' (e.g. --from, --enable-web-dashboard)
    # may be parsed as gemini options. Verify serena registration manually.
    gemini mcp add -s user $env_flags_gemini $name $cmd $args 2>/dev/null
    and echo "  ✅ Gemini"
    or  echo "  ⏭️  Gemini (already exists or error)"
end

# ── 2. Remote MCP servers (Claude Code only) ──
echo ""
echo "=== Remote MCP servers (SSE/HTTP) ==="

if not test -f "$remote_config"
    echo "  ⏭️  No remote-servers.json found, skipping"
else
    for name in (jq -r 'keys[]' "$remote_config")
        set url       (jq -r --arg n $name '.[$n].url'       "$remote_config")
        set transport (jq -r --arg n $name '.[$n].transport' "$remote_config")
        claude mcp add --transport $transport --scope user $name $url 2>/dev/null
        and echo "  ✅ Claude Code: $name"
        or  echo "  ⏭️  Claude Code: $name (already exists)"
    end
end

echo ""
echo "✅ Setup complete!"
echo ""
echo "⚠️  Restart each client for changes to take effect."
echo "📋 Remote servers (OAuth): run /mcp in each client to authenticate on first use."
