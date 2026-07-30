function agent-status -d "Show AI agent status from state files (no zellij polling)"
    # Sources, cheapest first — no multiplexer round-trips:
    #   1. ~/.claude/sessions/<pid>.json  : written by Claude Code itself (v2.1.119+),
    #      authoritative status: busy / shell / idle / waiting (+ waitingFor detail)
    #   2. /tmp/agent-state/<session>_<pane>.json : written by notify hooks on
    #      permission prompts (claude/codex/...), removed on Stop
    #   3. one ps pass : presence of non-claude agents that have no state file
    set -l state_dir /tmp/agent-state
    set -l rows

    # Nerd Font glyphs built from codepoints (raw PUA chars in source are
    # fragile — editors/LLMs corrupt them silently)
    set -l g_bolt (printf '\uf0e7') # busy
    set -l g_term (printf '\uf120') # shell: agent idle but local bash running
    set -l g_zzz (printf '\U000f04b2') # idle (md-sleep)
    set -l g_lock (printf '\uf023') # waiting: permission prompt
    set -l g_quest (printf '\uf059') # waiting: input needed
    set -l g_cube (printf '\uf1b2') # waiting: sandbox request
    set -l g_win (printf '\uf2d0') # waiting: dialog open
    set -l g_robot (printf '\U000f06a9') # worker request / non-claude agents
    set -l reset (set_color normal)

    # GC hook files older than 1 day
    if test -d $state_dir
        find $state_dir -name '*.json' -mmin +1440 -delete 2>/dev/null
    end

    # 1. Claude Code native probes
    for f in ~/.claude/sessions/*.json
        test -f $f; or continue
        set -l data (jq -r '[.pid, .status // "busy", .name // "claude", .cwd // "", .waitingFor // "", .kind // "interactive"] | @tsv' $f 2>/dev/null)
        test -n "$data"; or continue
        echo $data | read -d \t pid st name cwd wf kind
        # skip probes left behind by dead processes
        kill -0 $pid 2>/dev/null; or continue
        set -l repo -
        test -n "$cwd"; and set repo (path basename -- $cwd)
        test "$kind" != interactive; and set name "$name [$kind]"
        set -l icon $g_bolt
        set -l color (set_color green)
        switch $st
            case idle
                set icon $g_zzz
                set color (set_color brblack)
            case shell
                set icon $g_term
                set color (set_color cyan)
            case waiting
                test -n "$wf"; and set st $wf
                switch $wf
                    case "input needed"
                        set icon $g_quest
                        set color (set_color magenta)
                    case "sandbox request"
                        set icon $g_cube
                        set color (set_color red)
                    case "worker request"
                        set icon $g_robot
                        set color (set_color red)
                    case "dialog open"
                        set icon $g_win
                        set color (set_color yellow)
                    case '*'
                        set icon $g_lock
                        set color (set_color red)
                end
        end
        set -a rows (printf "%s%s%s %-8s %-10s %-18s %s" $color $icon $reset claude $repo $st $name)
    end

    # 2. Hook state files: agents waiting on permission/user input
    set -l hooked_agents
    for f in $state_dir/*.json
        test -f $f; or continue
        set -l data (jq -r '[.agent // "?", .status // "?"] | @tsv' $f 2>/dev/null)
        test -n "$data"; or continue
        echo $data | read -d \t agent st
        set -a hooked_agents $agent
        # claude blocked states come from probes too; hook file adds pane location
        set -l where (path basename -- $f | string replace -r '\.json$' '')
        set -a rows (printf "%s%s%s %-8s %-10s %-18s %s" (set_color red) $g_lock $reset $agent $where $st "")
    end

    # 3. Other running agents without state files
    for line in (ps -Ao pid=,command=)
        set -l m (string match -r '^\s*\d+\s+(?:\S*/)?(codex|copilot|opencode|aider)(\s|$)' -- $line)
        test -n "$m"; or continue
        set -l agent $m[2]
        contains $agent $hooked_agents; and continue
        set -a rows (printf "%s%s%s %-8s %-10s %-18s %s" (set_color green) $g_robot $reset $agent - running "")
    end

    if test (count $rows) -eq 0
        echo "No agents running"
        return 0
    end

    printf "  %-8s %-10s %-18s %s\n" AGENT WHERE STATE NAME
    printf "  %-8s %-10s %-18s %s\n" ───── ───── ───── ────
    for row in $rows
        echo $row
    end
end
