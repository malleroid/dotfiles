function agent-status -d "Show AI agent status across all Zellij sessions"
    set -l sessions (zellij list-sessions -s 2>/dev/null)
    if test -z "$sessions"
        echo "No Zellij sessions found"
        return 1
    end

    # Clean stale state files (older than 3 minutes)
    set -l state_dir /tmp/agent-state
    if test -d $state_dir
        find $state_dir -name '*.json' -mmin +1440 -delete 2>/dev/null
    end

    set -l found 0

    for sess in $sessions
        set -l json (zellij -s $sess action list-panes --json -c -t 2>/dev/null)
        if test -z "$json"
            continue
        end

        set -l agents (echo $json | jq -r --arg sess "$sess" --arg state_dir "$state_dir" '
            .[] |
            select(.is_plugin == false) |
            select(
                .pane_command == "claude" or
                (.pane_command // "" | test("codex")) or
                (.pane_command // "" | test("copilot")) or
                (.pane_command // "" | test("opencode")) or
                (.pane_command // "" | test("aider"))
            ) |
            .id as $pane_id |
            ($state_dir + "/" + $sess + "_" + ($pane_id | tostring) + ".json") as $state_file |
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
                pane_id: $pane_id,
                title_state: (
                    if (.title | startswith("✳")) then "idle"
                    elif (.title | contains("| process")) then "working"
                    elif (.title | contains("| idle")) then "idle"
                    elif (.title | contains("| waiting")) then "blocked"
                    else "working"
                    end
                )
            } |
            "\(.agent)\t\(.tab)\t\(.title)\t\(.pane_id)\t\(.title_state)"
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
                echo $line | read -d \t agent tab title pane_id title_state

                # Check hook-written state file for blocked detection
                set -l state_file "$state_dir/"$sess"_"$pane_id".json"
                set -l final_state $title_state
                if test -f $state_file
                    set final_state blocked
                end

                switch $final_state
                    case blocked
                        set icon 🔴
                    case working
                        set icon 🟢
                    case idle
                        set icon 🟠
                    case '*'
                        set icon 🟢
                end

                printf "%-13s %-14s %s\n" "$icon $agent" "$tab" "$title"
            end
            set found (math $found + 1)
        end
    end

    if test $found -eq 0
        echo "No agents running"
    end
end
