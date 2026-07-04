function __agent_pane_title --on-event fish_preexec
    if not set -q ZELLIJ_PANE_ID
        return
    end
    switch (string split ' ' -- $argv[1])[1]
        case claude codex copilot opencode aider
            zellij action rename-pane $argv[1]
    end
end
