function _tp_connect_link -d "Map a target to a TablePlus connection UUID, matching on the forwarded local port"
    set -l target $argv[1]
    test -n "$target"; or return 1

    if not type -q jq
        echo "tp-connect: jq is required for --link" >&2
        return 1
    end
    if not type -q fzf
        echo "tp-connect: fzf is required for --link" >&2
        return 1
    end

    set -l connections (_tp_connect_connections)
    if test (count $connections) -eq 0
        echo "tp-connect: no TablePlus connections found" >&2
        return 1
    end

    set -l local_port (_tp_connect_lookup $target)
    set -l candidates
    if test -n "$local_port"
        for connection in $connections
            set -l fields (string split \t -- $connection)
            test "$fields[4]" = "$local_port"; and set -a candidates $connection
        end
    end

    set -l line
    switch (count $candidates)
        case 1
            set line $candidates[1]
            echo "tp-connect: port $local_port matches "(string split \t -- $line)[2]
        case 0
            test -n "$local_port"
            and echo "tp-connect: no TablePlus connection listens on $local_port, showing all" >&2
            set line (printf '%s\n' $connections \
                | fzf --delimiter=\t --with-nth=2,3,4 --prompt="TablePlus connection for $target> ")
        case '*'
            set line (printf '%s\n' $candidates \
                | fzf --delimiter=\t --with-nth=2,3 --prompt="TablePlus connection for $target (port $local_port)> ")
    end

    test -n "$line"; or return 1
    set -l uuid (string split \t -- $line)[1]
    test -n "$uuid"; or return 1

    set -l config_dir (set -q TP_CONNECT_CONFIG_DIR; and echo $TP_CONNECT_CONFIG_DIR; or echo $HOME/.config/tp-connect)
    set -l ids_file $config_dir/ids.fish
    mkdir -p $config_dir

    if not test -e $ids_file
        printf "# tp-connect: target -> TablePlus connection UUID\n# Add or edit lines manually, or use 'tp-connect --link <target>'.\n\n" >$ids_file
    end

    set -l key _tp_id_(string replace -a '-' '_' $target)
    string match -v -r "^set -g $key " <$ids_file >$ids_file.new
    mv $ids_file.new $ids_file
    printf "set -g %s '%s'\n" $key $uuid >>$ids_file

    echo "tp-connect: linked $target -> $uuid"
    echo "  written to $ids_file"
end
