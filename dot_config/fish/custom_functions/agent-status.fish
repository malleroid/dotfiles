function _agent_status_icon -a agent
    # Agent identity, one cell each. Built from codepoints for the same reason
    # as the state glyphs below.
    switch $agent
        case claude
            printf '\U00002733' # sextile
        case codex
            printf '\U000025c8' # diamond in diamond
        case copilot
            printf '\U00002708' # airplane
        case opencode
            printf '\U00002b21' # white hexagon
        case aider
            printf '\U0000271a' # heavy greek cross
        case '*'
            printf '?'
    end
end

function _agent_status_cell -a text width
    # printf pads by character count; string pad/shorten measure display width,
    # so multibyte session names keep the columns aligned
    set -l cell (string shorten -m $width -- "$text")
    test -n "$cell"; or set cell ""
    string pad -r -w $width -- "$cell"
end

function agent-status -d "Show AI agent status from state files (no zellij polling)"
    # Sources, cheapest first — no multiplexer round-trips:
    #   1. ~/.claude/sessions/<pid>.json  : written by Claude Code itself (v2.1.119+),
    #      authoritative status: busy / shell / idle / waiting (+ waitingFor detail)
    #   2. /tmp/agent-state/<session>_<pane>.json : written by notify hooks on
    #      permission prompts (claude/codex/...), removed on Stop
    #   3. one ps pass : presence of non-claude agents that have no state file
    set -l state_dir /tmp/agent-state
    set -l rows

    # Budget: 36 cols. The floating pane is 17% wide, so the narrowest terminal
    # in use (237 cols) still gives 40 cols minus its 2-col frame.
    # 2 icons + 3 gaps = 6, leaving 30 for the text columns.
    set -l w_name 13
    set -l w_where 10
    set -l w_state 7

    # Nerd Font glyphs built from codepoints (raw PUA chars in source are
    # fragile — editors/LLMs corrupt them silently)
    set -l g_bolt (printf '\U0000f0e7') # busy
    set -l g_term (printf '\U0000f120') # shell: agent idle but local bash running
    set -l g_zzz (printf '\U000f04b2') # idle (md-sleep)
    set -l g_lock (printf '\U0000f023') # waiting: permission prompt
    set -l g_quest (printf '\U0000f059') # waiting: input needed
    set -l g_cube (printf '\U0000f1b2') # waiting: sandbox request
    set -l g_win (printf '\U0000f2d0') # waiting: dialog open
    set -l g_robot (printf '\U000f06a9') # waiting: worker request
    set -l reset (set_color normal)

    # GC hook files older than 1 day
    if test -d $state_dir
        find $state_dir -name '*.json' -mmin +1440 -delete 2>/dev/null
    end

    # 1. Claude Code native probes
    for f in ~/.claude/sessions/*.json
        test -f $f; or continue
        set -l data (jq -r '[.pid, .status // "busy", .name // "", .cwd // "", .waitingFor // ""] | @tsv' $f 2>/dev/null)
        test -n "$data"; or continue
        echo $data | read -d \t pid st name cwd wf
        # skip probes left behind by dead processes
        kill -0 $pid 2>/dev/null; or continue
        set -l repo -
        test -n "$cwd"; and set repo (path basename -- $cwd)
        set -l icon $g_bolt
        set -l color (set_color green)
        set -l label busy
        switch $st
            case idle
                set icon $g_zzz
                set color (set_color brblack)
                set label idle
            case shell
                set icon $g_term
                set color (set_color cyan)
                set label shell
            case waiting
                switch $wf
                    case "input needed"
                        set icon $g_quest
                        set color (set_color magenta)
                        set label input
                    case "sandbox request"
                        set icon $g_cube
                        set color (set_color red)
                        set label sandbox
                    case "worker request"
                        set icon $g_robot
                        set color (set_color red)
                        set label worker
                    case "dialog open"
                        set icon $g_win
                        set color (set_color yellow)
                        set label dialog
                    case '*'
                        set icon $g_lock
                        set color (set_color red)
                        set label perm
                end
        end
        set -a rows (printf '%s%s%s %s %s %s %s' $color $icon $reset (_agent_status_icon claude) (_agent_status_cell "$name" $w_name) (_agent_status_cell "$repo" $w_where) $label)
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
        # keep the tail: the pane id is what actually locates the agent
        set where (string shorten -m $w_where --left -- $where)
        set -l icon $g_lock
        set -l color (set_color red)
        set -l label perm
        switch $st
            case asking_permissions
                # same event as a native "waiting" probe, so same icon/label
            case waiting_user_answers
                set icon $g_quest
                set color (set_color magenta)
                set label input
            case '*'
                set label (string shorten -m $w_state -- $st)
        end
        set -a rows (printf '%s%s%s %s %s %s %s' $color $icon $reset (_agent_status_icon $agent) (_agent_status_cell - $w_name) (_agent_status_cell "$where" $w_where) $label)
    end

    # 3. Other running agents without state files
    for line in (ps -Ao pid=,command=)
        set -l m (string match -r '^\s*\d+\s+(?:\S*/)?(codex|copilot|opencode|aider)(\s|$)' -- $line)
        test -n "$m"; or continue
        set -l agent $m[2]
        contains $agent $hooked_agents; and continue
        set -a rows (printf '%s%s%s %s %s %s %s' (set_color green) $g_bolt $reset (_agent_status_icon $agent) (_agent_status_cell - $w_name) (_agent_status_cell - $w_where) running)
    end

    if test (count $rows) -eq 0
        echo "No agents running"
        return 0
    end

    printf "    %s %s %s\n" (_agent_status_cell NAME $w_name) (_agent_status_cell WHERE $w_where) STATE
    printf "    %s %s %s\n" (string repeat -n $w_name ─) (string repeat -n $w_where ─) (string repeat -n $w_state ─)
    for row in $rows
        echo $row
    end
end
