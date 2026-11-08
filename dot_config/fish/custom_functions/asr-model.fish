function asr-model --description "Resolve an ASR model declared in ~/.config/asr/models.toml"
    # asr-model <engine> [name]   print the value to pass as the engine's model
    # asr-model --list <engine>   print the declared models of an engine
    set --local manifest ~/.config/asr/models.toml
    set -q ASR_MODELS; and set manifest $ASR_MODELS
    if not test -f $manifest
        echo "asr-model: $manifest not found" >&2
        return 1
    end
    set --local json (dasel -i toml -o json --compact --root <$manifest)
    or return 1

    if test "$argv[1]" = --list
        echo $json | jq -r --arg e $argv[2] '
            .[$e] as $t
            | $t | to_entries[] | select(.value | type == "object")
            | "  \(.key)\(if .key == $t.default then " (default)" else "" end)"
              + "\(if .value.aliases then " [" + (.value.aliases | join(", ")) + "]" else "" end)"
              + "  \(.value.source)"'
        return
    end

    set --local engine $argv[1]
    set --local name $argv[2]
    if test -z "$name"
        set name (echo $json | jq -r --arg e $engine '.[$e].default // empty')
    end

    set --local entry (echo $json | jq -c --arg e $engine --arg n $name '
        (.[$e] // {}) | to_entries
        | map(select(.value | type == "object")
              | select(.key == $n or any((.value.aliases // [])[]; . == $n)))
        | first.value // empty')

    if test -z "$entry"
        # Undeclared repo ids and paths pass through unpinned
        if string match --quiet --regex '[/~]' -- $name
            echo $name
            return
        end
        echo "asr-model: unknown $engine model: $name" >&2
        asr-model --list $engine >&2
        return 1
    end

    set --local source (echo $entry | jq -r .source)
    switch $source
        case 'hf:*'
            set --local repo (string replace hf: '' -- $source)
            set --local rev (echo $entry | jq -r '.revision // empty')
            if test -z "$rev"
                echo "asr-model: $name has no pinned revision in $manifest" >&2
                return 1
            end
            set --local hub ~/.cache/huggingface/hub
            set -q HF_HOME; and set hub $HF_HOME/hub
            set -q HF_HUB_CACHE; and set hub $HF_HUB_CACHE
            set --local dir $hub/models--(string replace --all -- / -- $repo)/snapshots/$rev
            if not test -d $dir
                echo "asr-model: $repo@$rev is not downloaded. Run:" >&2
                echo "  hf download $repo --revision $rev" >&2
                return 1
            end
            echo $dir
        case 'local:*'
            set --local dir (string replace --regex '^local:~' $HOME -- $source)
            set dir (string replace local: '' -- $dir)
            if not test -e $dir
                echo "asr-model: $dir does not exist; see docs/asr-models.md in the dotfiles repo" >&2
                return 1
            end
            echo $dir
        case 'speech:*'
            string replace speech: '' -- $source
        case '*'
            echo "asr-model: unknown source for $name: $source" >&2
            return 1
    end
end
