function _tp_connect_id -d "Resolve the TablePlus connection UUID for a target"
    set -l target $argv[1]
    test -n "$target"; or return 1

    set -l config_dir (set -q TP_CONNECT_CONFIG_DIR; and echo $TP_CONNECT_CONFIG_DIR; or echo $HOME/.config/tp-connect)
    set -l ids_file $config_dir/ids.fish
    set -l key _tp_id_(string replace -a '-' '_' $target)

    if test -r $ids_file
        source $ids_file
        if set -q $key
            echo $$key
            return 0
        end
    end

    # Not linked yet: fall back to the TablePlus connection on this target's
    # forwarded local port, but only when that leaves exactly one candidate.
    set -l local_port (_tp_connect_lookup $target)
    test -n "$local_port"; or return 1

    set -l matches
    for connection in (_tp_connect_connections)
        set -l fields (string split \t -- $connection)
        test "$fields[4]" = "$local_port"; and set -a matches $fields[1]
    end

    test (count $matches) -eq 1; or return 1
    echo $matches[1]
end
