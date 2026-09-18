#!/usr/bin/env fish
# MCP Server Setup Script
# Configures stdio, local HTTP, and remote servers for all clients

set script_dir (status dirname)
set servers_config "$script_dir/servers.json"
set local_config "$script_dir/local-servers.json"
set remote_config "$script_dir/remote-servers.json"
set desktop_cfg "$HOME/Library/Application Support/Claude/claude_desktop_config.json"

# ── Helper: register an HTTP/SSE server to Claude Code & Claude Desktop ──
function _register_http_server --argument-names name url transport
    # Claude Code (remove + add for upsert)
    claude mcp remove --scope user $name 2>/dev/null
    claude mcp add --transport $transport --scope user $name $url 2>/dev/null
    and echo "  ✅ Claude Code: $name"
    or  echo "  ❌ Claude Code: $name (failed)"

    # Claude Desktop
    if test -f "$desktop_cfg"
        set entry (printf '{"url":"%s"}' $url)
        jq --arg n $name --argjson e $entry '.mcpServers[$n] = $e' "$desktop_cfg" \
            > "$script_dir/_tmp_desktop.json"
        and mv "$script_dir/_tmp_desktop.json" "$desktop_cfg"
        and echo "  ✅ Claude Desktop: $name"
        or  echo "  ❌ Claude Desktop: $name (failed to update)"
    else
        echo "  ⏭️  Claude Desktop: $name (config not found)"
    end
end

# ── Helper: list the MCP server names stored in a client's JSON config ──
function _mcp_names_from_json --argument-names file
    if test -s "$file"
        jq -r '.mcpServers // {} | keys[]' "$file" 2>/dev/null
    end
end

# ── Helper: drop a server from every client ──
# Clients with an MCP CLI are asked directly; the rest are edited as JSON.
function _unregister_server --argument-names name
    claude mcp remove --scope user $name 2>/dev/null
    and echo "  ✅ Claude Code"
    or  echo "  ⏭️  Claude Code (not registered)"

    codex mcp remove $name 2>/dev/null
    and echo "  ✅ Codex"
    or  echo "  ⏭️  Codex (not registered)"

    copilot mcp remove $name 2>/dev/null
    and echo "  ✅ Copilot"
    or  echo "  ⏭️  Copilot (not registered)"

    _delete_from_json "$desktop_cfg" $name "Claude Desktop" desktop
    _delete_from_json "$HOME/.gemini/config/mcp_config.json" $name "Antigravity CLI (agy)" agy
end

# ── Helper: delete one .mcpServers entry from a JSON config ──
function _delete_from_json --argument-names file name label slug
    if not test -s "$file"
        echo "  ⏭️  $label (config not found)"
        return
    end
    if not _mcp_names_from_json "$file" | string match -q -- $name
        echo "  ⏭️  $label (not registered)"
        return
    end
    jq --arg n $name 'del(.mcpServers[$n])' "$file" \
        > "$script_dir/_tmp_$slug.json"
    and mv "$script_dir/_tmp_$slug.json" "$file"
    and echo "  ✅ $label"
    or  echo "  ❌ $label (failed to update)"
end

# ── 1. stdio servers ──
echo "=== stdio MCP servers ==="

for name in (jq -r 'keys[]' "$servers_config")
    set cmd  (jq -r --arg n $name '.[$n].command' "$servers_config")
    set args (jq -r --arg n $name '.[$n].args[]'  "$servers_config")

    # Build env flags per client
    set env_flags_claude
    set env_flags_codex
    for key in (jq -r --arg n $name '.[$n].env | keys[]' "$servers_config")
        set val (jq -r --arg n $name --arg k $key '.[$n].env[$k]' "$servers_config")
        set env_flags_claude $env_flags_claude -e "$key=$val"
        set env_flags_codex  $env_flags_codex  --env "$key=$val"
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
    if test -f "$desktop_cfg"
        set mise_path "$HOME/.local/share/mise/shims"
        set default_path "$mise_path:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        set entry (jq -c --arg n $name --arg path "$default_path" \
            '{command: .[$n].command, args: .[$n].args, env: (.[$n].env + {PATH: $path})}' \
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

    # Antigravity CLI (agy): write to ~/.gemini/config/mcp_config.json (global)
    # NOTE: agy creates this file empty on first run, so check size (-s) not just
    # existence (-f) — otherwise jq would read invalid (empty) JSON.
    set agy_cfg "$HOME/.gemini/config/mcp_config.json"
    mkdir -p (dirname "$agy_cfg")
    if not test -s "$agy_cfg"
        echo '{"mcpServers":{}}' > "$agy_cfg"
    end
    set entry (jq -c --arg n $name \
        '{command: .[$n].command, args: .[$n].args, env: .[$n].env}' \
        "$servers_config")
    jq --arg n $name --argjson e $entry '.mcpServers[$n] = $e' "$agy_cfg" \
        > "$script_dir/_tmp_agy.json"
    and mv "$script_dir/_tmp_agy.json" "$agy_cfg"
    and echo "  ✅ Antigravity CLI (agy)"
    or  echo "  ❌ Antigravity CLI (failed)"
end

# ── 2. Local HTTP servers (Claude Code + Claude Desktop) ──
echo ""
echo "=== Local MCP servers (HTTP) ==="

if not test -f "$local_config"
    echo "  ⏭️  No local-servers.json found, skipping"
else
    for name in (jq -r 'keys[]' "$local_config")
        set url       (jq -r --arg n $name '.[$n].url'       "$local_config")
        set transport (jq -r --arg n $name '.[$n].transport' "$local_config")
        _register_http_server $name $url $transport
    end
end

# ── 3. Remote MCP servers (Claude Code + Copilot CLI) ──
echo ""
echo "=== Remote MCP servers (SSE/HTTP) ==="

if not test -f "$remote_config"
    echo "  ⏭️  No remote-servers.json found, skipping"
else
    for name in (jq -r 'keys[]' "$remote_config")
        set url       (jq -r --arg n $name '.[$n].url'         "$remote_config")
        set transport (jq -r --arg n $name '.[$n].transport'   "$remote_config")
        set auth      (jq -r --arg n $name '.[$n].auth // ""'  "$remote_config")

        echo ""
        echo "  [$name]"

        # Claude Code (remove + add for upsert)
        claude mcp remove --scope user $name 2>/dev/null
        claude mcp add --transport $transport --scope user $name $url 2>/dev/null
        and echo "  ✅ Claude Code"
        or  echo "  ❌ Claude Code (failed)"

        # Copilot CLI (HTTP/SSE; transport -> type, OAuth auto-negotiated via DCR)
        set copilot_cfg "$HOME/.copilot/mcp-config.json"
        if not test -f "$copilot_cfg"
            mkdir -p ~/.copilot
            echo '{"mcpServers":{}}' > "$copilot_cfg"
        end
        set entry (jq -c --arg n $name \
            '{type: .[$n].transport, url: .[$n].url, tools: ["*"]}' \
            "$remote_config")
        jq --arg n $name --argjson e $entry '.mcpServers[$n] = $e' "$copilot_cfg" \
            > "$script_dir/_tmp_copilot.json"
        and mv "$script_dir/_tmp_copilot.json" "$copilot_cfg"
        and echo "  ✅ Copilot"
        or  echo "  ❌ Copilot (failed)"

        # OAuth servers need a one-time browser auth (cannot be scripted)
        if test "$auth" = oauth
            echo "  🔑 OAuth: run '/mcp auth $name' in Copilot on first use"
        end
    end
end

# ── 4. Prune servers that are registered but no longer in the config ──
echo ""
echo "=== Orphaned MCP servers ==="

set desired
for cfg in "$servers_config" "$local_config" "$remote_config"
    if test -f "$cfg"
        set desired $desired (jq -r 'keys[]' "$cfg")
    end
end

set prune_names
set prune_labels

function _collect_orphans --argument-names label
    for name in $argv[2..]
        if contains -- $name $desired
            continue
        end
        set idx (contains -i -- $name $prune_names)
        if test -n "$idx"
            set prune_labels[$idx] "$prune_labels[$idx], $label"
        else
            set -a prune_names $name
            set -a prune_labels $label
        end
    end
end

_collect_orphans "Claude Code" (_mcp_names_from_json "$HOME/.claude.json")
_collect_orphans "Claude Desktop" (_mcp_names_from_json "$desktop_cfg")
_collect_orphans Copilot (_mcp_names_from_json "$HOME/.copilot/mcp-config.json")
_collect_orphans Antigravity (_mcp_names_from_json "$HOME/.gemini/config/mcp_config.json")
_collect_orphans Codex (codex mcp list --json 2>/dev/null | jq -r '.[].name' 2>/dev/null)

if test (count $prune_names) -eq 0
    echo "  ⏭️  None"
else
    echo "  These servers are registered but no longer in the config files:"
    for i in (seq (count $prune_names))
        echo "    - $prune_names[$i]  ($prune_labels[$i])"
    end
    echo ""

    # Non-interactive runs (chezmoi, CI) must never delete without a human.
    if not isatty stdin
        echo "  ⏭️  Skipped: not a TTY. Re-run this script interactively to remove them."
    else
        read -P "  Remove them from every client? [y/N] " answer
        if string match -qir '^y(es)?$' -- $answer
            for name in $prune_names
                echo ""
                echo "  [$name]"
                _unregister_server $name
            end
        else
            echo "  ⏭️  Kept"
        end
    end
end

echo ""
echo "✅ Setup complete!"
echo ""
echo "⚠️  Restart each client for changes to take effect."
echo "📋 Remote servers (OAuth): run /mcp in each client to authenticate on first use."
