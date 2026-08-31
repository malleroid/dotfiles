function _tp_connect_connections -d "List TablePlus saved connections as id<TAB>name<TAB>driver<TAB>port"
    set -l plist (_tp_connect_plist)
    test -n "$plist"; or return 1
    type -q jq; or return 1

    plutil -convert json -o - "$plist" 2>/dev/null \
        | jq -r '
            [.. | objects | select(has("ID"))
              | {
                  id: .ID,
                  name: (.ConnectionName // .Name // .name // "(unnamed)"),
                  driver: (.DriverDisplayName // .Driver // .ConnectionType // ""),
                  port: ((.DatabasePort // "") | tostring)
                }
            ]
            | unique_by(.id)
            | .[]
            | "\(.id)\t\(.name)\t\(.driver)\t\(.port)"
        '
end
