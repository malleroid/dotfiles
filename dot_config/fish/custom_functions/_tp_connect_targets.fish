function _tp_connect_targets -d "List connect_db / connect_ec2 targets parsed from gi-no/infra zsh completions"
    set -l kind $argv[1]
    set -l dir (_tp_connect_infra_dir $kind); or return 1

    set -l file
    switch $kind
        case db
            set file $dir/_connect_db
        case ec2
            set file $dir/_connect_ec2
        case '*'
            return 1
    end

    test -r $file; or return 1
    string match -rg "'([^']+)'" <$file
end
