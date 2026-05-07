function _tp_connect_id -d "Resolve TablePlus connection UUID for a target from private config"
    set -l target $argv[1]
    set -l config_dir (set -q TP_CONNECT_CONFIG_DIR; and echo $TP_CONNECT_CONFIG_DIR; or echo $HOME/.config/tp-connect)
    set -l ids_file $config_dir/ids.fish

    test -r $ids_file; or return 1
    source $ids_file

    set -l key _tp_id_(string replace -a '-' '_' $target)
    set -q $key; or return 1
    echo $$key
end
