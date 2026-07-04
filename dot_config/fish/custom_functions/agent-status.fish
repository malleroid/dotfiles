function agent-status -d "Show AI agent status across all Zellij sessions"
    set -l sessions (zellij list-sessions -s 2>/dev/null)
    if test -z "$sessions"
        echo "No Zellij sessions found"
        return 1
    end

    set -l found 0

    for sess in $sessions
        set -l json (zellij -s $sess action list-panes --json -c -t 2>/dev/null)
        if test -z "$json"
            continue
        end

        set -l agents (echo $json | jq -r '
            .[] |
            select(.is_plugin == false) |
            select(
                .pane_command == "claude" or
                (.pane_command // "" | test("codex")) or
                (.pane_command // "" | test("copilot")) or
                (.pane_command // "" | test("opencode")) or
                (.pane_command // "" | test("aider"))
            ) |
            {
                agent: (
                    if .pane_command == "claude" then "claude"
                    elif (.pane_command // "" | test("codex")) then "codex"
                    elif (.pane_command // "" | test("copilot")) then "copilot"
                    elif (.pane_command // "" | test("opencode")) then "opencode"
                    elif (.pane_command // "" | test("aider")) then "aider"
                    else .pane_command
                    end
                ),
                tab: .tab_name,
                title: .title,
                state: (
                    if (.title | startswith("✳")) then "idle"
                    elif (.title | contains("| process")) then "working"
                    elif (.title | contains("| idle")) then "idle"
                    elif (.title | contains("| waiting")) then "blocked"
                    else "working"
                    end
                ),
                icon: (
                    if (.title | startswith("✳")) then "🟠"
                    elif (.title | contains("| process")) then "🟢"
                    elif (.title | contains("| idle")) then "🟠"
                    elif (.title | contains("| waiting")) then "🔴"
                    else "🟢"
                    end
                )
            } |
            "\(.icon) \(.agent)\t\(.tab)\t\(.title)"
        ' 2>/dev/null)

        if test -n "$agents"
            if test $found -eq 0
                printf "%-4s %-8s %-14s %s\n" "ST" "AGENT" "TAB" "NAME"
                printf "%-4s %-8s %-14s %s\n" "──" "─────" "───" "────"
            end
            if test $found -gt 0; or test (count $sessions) -gt 1
                echo "── $sess ──"
            end
            for line in $agents
                echo $line | read -d \t icon_agent tab title
                printf "%-13s %-14s %s\n" "$icon_agent" "$tab" "$title"
            end
            set found (math $found + 1)
        end
    end

    if test $found -eq 0
        echo "No agents running"
    end
end
