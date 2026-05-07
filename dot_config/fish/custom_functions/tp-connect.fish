function tp-connect -d "Open a TablePlus saved connection through a connect_db SSM port forward"
    argparse 'h/help' 'l/link' 't/timeout=' -- $argv
    or return 1

    if set -q _flag_help
        echo "tp-connect [target]"
        echo "tp-connect --link [target]"
        echo ""
        echo "  Open a TablePlus saved connection (by UUID) via a gi-no/infra"
        echo "  connect_db SSM port forward, and tear down the SSM session once"
        echo "  the TablePlus connection closes."
        echo ""
        echo "Args:"
        echo "  target              connect_db target name (omit to pick via fzf)"
        echo ""
        echo "Options:"
        echo "  -l, --link          map target -> TablePlus UUID (writes to ids.fish)"
        echo "  -t, --timeout SEC   wait up to SEC for TablePlus to connect (default: 60)"
        echo "  -h, --help          show this help"
        echo ""
        echo "Env:"
        echo "  TP_CONNECT_INFRA_CONNECT_DB_DIR  override _connect_db dir"
        echo "  TP_CONNECT_CONFIG_DIR            ids.fish dir (default: ~/.config/tp-connect)"
        return 0
    end

    set -l target $argv[1]
    if test -z "$target"
        if not type -q fzf
            echo "tp-connect: fzf is required when no target is given" >&2
            return 1
        end
        set target (_tp_connect_targets db | fzf --prompt='target> ')
        test -n "$target"; or return 1
    end

    if set -q _flag_link
        _tp_connect_link $target
        return $status
    end

    set -l establish_timeout (set -q _flag_timeout; and echo $_flag_timeout; or echo 60)

    set -l local_port (_tp_connect_lookup $target)
    if test -z "$local_port"
        echo "tp-connect: failed to resolve local_port for '$target'" >&2
        return 1
    end

    set -l uuid (_tp_connect_id $target)
    if test -z "$uuid"
        set -l config_dir (set -q TP_CONNECT_CONFIG_DIR; and echo $TP_CONNECT_CONFIG_DIR; or echo $HOME/.config/tp-connect)
        echo "tp-connect: TablePlus UUID not configured for '$target'" >&2
        echo "  Run: tp-connect --link $target" >&2
        echo "  (writes to $config_dir/ids.fish)" >&2
        return 1
    end

    echo "tp-connect: starting SSM port forward (target=$target, local_port=$local_port)"
    connect_db $target &
    set -l ssm_pid $last_pid

    function __tp_connect_cleanup --inherit-variable ssm_pid --on-signal INT --on-signal TERM
        if test -n "$ssm_pid"; and kill -0 $ssm_pid 2>/dev/null
            pkill -TERM -P $ssm_pid 2>/dev/null
            kill -TERM $ssm_pid 2>/dev/null
        end
    end

    set -l ticks 0
    while not nc -z localhost $local_port 2>/dev/null
        if not kill -0 $ssm_pid 2>/dev/null
            echo "tp-connect: connect_db exited before the port came up" >&2
            functions -e __tp_connect_cleanup
            return 1
        end
        sleep 0.2
        set ticks (math $ticks + 1)
        if test $ticks -ge 150
            echo "tp-connect: timed out waiting for local port $local_port to LISTEN" >&2
            __tp_connect_cleanup
            wait $ssm_pid 2>/dev/null
            functions -e __tp_connect_cleanup
            return 1
        end
    end

    echo "tp-connect: opening TablePlus"
    open "tableplus://?id=$uuid"

    set ticks 0
    set -l max_ticks (math "$establish_timeout * 2")
    while not lsof -i :$local_port -sTCP:ESTABLISHED >/dev/null 2>&1
        if not kill -0 $ssm_pid 2>/dev/null
            echo "tp-connect: connect_db exited before TablePlus connected" >&2
            functions -e __tp_connect_cleanup
            return 1
        end
        sleep 0.5
        set ticks (math $ticks + 1)
        if test $ticks -ge $max_ticks
            echo "tp-connect: timed out waiting for TablePlus to connect" >&2
            __tp_connect_cleanup
            wait $ssm_pid 2>/dev/null
            functions -e __tp_connect_cleanup
            return 1
        end
    end

    echo "tp-connect: connected — close TablePlus to release the SSM session"
    set -l idle 0
    while true
        if lsof -i :$local_port -sTCP:ESTABLISHED >/dev/null 2>&1
            set idle 0
        else
            set idle (math $idle + 1)
            test $idle -ge 6; and break
        end
        sleep 0.5
    end

    echo "tp-connect: closing SSM session"
    __tp_connect_cleanup
    wait $ssm_pid 2>/dev/null
    functions -e __tp_connect_cleanup
end
