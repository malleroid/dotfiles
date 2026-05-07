function _tp_connect_link -d "Map a target to a TablePlus connection UUID via fzf, append to ids.fish"
    set -l target $argv[1]
    test -n "$target"; or return 1

    set -l plist (_tp_connect_plist)
    if test -z "$plist"
        echo "tp-connect: TablePlus Connections.plist not found" >&2
        return 1
    end

    if not type -q jq
        echo "tp-connect: jq is required for --link" >&2
        return 1
    end
    if not type -q fzf
        echo "tp-connect: fzf is required for --link" >&2
        return 1
    end

    set -l line (plutil -convert json -o - "$plist" 2>/dev/null \
        | jq -r '
            [.. | objects | select(has("ID"))
              | {
                  id: .ID,
                  name: (.ConnectionName // .Name // .name // "(unnamed)"),
                  driver: (.DriverDisplayName // .Driver // .ConnectionType // "")
                }
            ]
            | unique_by(.id)
            | .[]
            | "\(.id)\t\(.name)\t\(.driver)"
        ' \
        | fzf --delimiter=\t --with-nth=2,3 --prompt="TablePlus connection for $target> ")

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
    printf "set -g %s '%s'\n" $key $uuid >>$ids_file

    echo "tp-connect: linked $target -> $uuid"
    echo "  written to $ids_file"
end
