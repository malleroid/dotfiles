function _tp_connect_infra_dir -d "Resolve gi-no/infra connect_{db,ec2} directory via setup.sh symlinks"
    set -l kind $argv[1]
    set -l env_var
    set -l symlink

    switch $kind
        case db
            set env_var TP_CONNECT_INFRA_CONNECT_DB_DIR
            set symlink /opt/homebrew/share/zsh/site-functions/_connect_db
        case ec2
            set env_var TP_CONNECT_INFRA_CONNECT_EC2_DIR
            set symlink /opt/homebrew/share/zsh/site-functions/_connect_ec2
        case '*'
            return 1
    end

    if set -q $env_var
        echo $$env_var
        return 0
    end

    test -L $symlink; or return 1
    dirname (readlink $symlink)
end
