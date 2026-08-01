function __agent_pane_title --on-event fish_preexec
    if not set -q ZELLIJ_PANE_ID
        return
    end

    set -l agent (string split ' ' -- $argv[1])[1]
    switch $agent
        case codex
            zellij action rename-pane $argv[1]

            # SessionStart does not fire until Codex creates a conversation.
            # Seed an idle row so a freshly launched process still has a cwd.
            set -q ZELLIJ_SESSION_NAME; or return
            set -l state_dir /tmp/agent-state
            set -q CODEX_AGENT_STATE_DIR; and set state_dir "$CODEX_AGENT_STATE_DIR"
            mkdir -p "$state_dir"; or return

            set -l state_file "$state_dir/"$ZELLIJ_SESSION_NAME"_"$ZELLIJ_PANE_ID.json
            set -l tmp_file "$state_file.tmp.$fish_pid"
            jq -n \
                --arg agent codex \
                --arg status idle \
                --arg cwd "$PWD" \
                --arg zellij_session "$ZELLIJ_SESSION_NAME" \
                --arg pane_id "$ZELLIJ_PANE_ID" \
                --argjson ts (date +%s) \
                '{agent: $agent, status: $status, sessionId: "", cwd: $cwd, zellijSession: $zellij_session, paneId: $pane_id, ts: $ts}' \
                >"$tmp_file"; and mv "$tmp_file" "$state_file"
        case copilot opencode aider
            zellij action rename-pane $argv[1]
    end
end

function __agent_launch_state_cleanup --on-event fish_postexec
    if not set -q ZELLIJ_SESSION_NAME; or not set -q ZELLIJ_PANE_ID
        return
    end
    if test (string split ' ' -- $argv[1])[1] = codex
        set -l state_dir /tmp/agent-state
        set -q CODEX_AGENT_STATE_DIR; and set state_dir "$CODEX_AGENT_STATE_DIR"
        # The first lifecycle hook removes this provisional file. If it still
        # exists after Codex exits, no conversation was ever created.
        rm -f "$state_dir/"$ZELLIJ_SESSION_NAME"_"$ZELLIJ_PANE_ID.json
    end
end
