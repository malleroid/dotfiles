function _tp_connect_lookup -d "Resolve local_port for a connect_db target via gi-no/infra env files"
    set -l target $argv[1]
    set -l dir (_tp_connect_infra_dir db); or return 1

    set -l env_file
    switch $target
        case '*-snd-ec2-*'
            set env_file sandbox
        case '*-stg-ec2-*'
            set env_file staging
        case '*-prd-ec2-*'
            set env_file production
        case '*'
            return 1
    end

    test -r $dir/$env_file; or return 1
    zsh -c "target_name='$target' source '$dir/$env_file' >/dev/null 2>&1; echo \$con_settings[4]" | string trim
end
