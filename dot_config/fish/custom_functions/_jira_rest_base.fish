function _jira_rest_base -d "Resolve Jira REST base (server, login, token) from jira-cli config + keychain/env"
    # Usage: set parts (_jira_rest_base [config_path]); or return
    #   parts[1] = server (no trailing slash), parts[2] = login, parts[3] = api token
    # Token resolution order mirrors jira-cli: $JIRA_API_TOKEN, then macOS keychain
    # (service 'jira-cli', account = login).
    set -l config $argv[1]

    if test -z "$config"
        if set -q JIRA_CONFIG_FILE
            set config $JIRA_CONFIG_FILE
        else
            for c in $HOME/.config/.jira/.config.yml $HOME/.jira/.config.yml
                if test -r $c
                    set config $c
                    break
                end
            end
        end
    end

    if test -z "$config"; or not test -r "$config"
        echo "jira: config not found (set --config or \$JIRA_CONFIG_FILE)" >&2
        return 1
    end

    set -l server (string match -rg '^\s*server:\s*(.+)$' < $config | string trim | string trim --chars '"' | string trim)
    set -l login (string match -rg '^\s*login:\s*(.+)$' < $config | string trim | string trim --chars '"' | string trim)
    set server (string replace -r '/$' '' -- $server)

    if test -z "$server"
        echo "jira: could not read 'server' from $config" >&2
        return 1
    end
    if test -z "$login"
        echo "jira: could not read 'login' from $config" >&2
        return 1
    end

    # Token resolution order mirrors jira-cli: env, then .netrc, then keychain.
    set -l host (string replace -r '^https?://' '' -- $server | string replace -r '/.*$' '')
    set -l token
    if set -q JIRA_API_TOKEN
        set token $JIRA_API_TOKEN
    else
        if test -r $HOME/.netrc; and type -q python3
            set token (python3 -c '
import netrc, sys
try:
    auth = netrc.netrc().authenticators(sys.argv[1])
    if auth and auth[2]:
        print(auth[2])
except Exception:
    pass
' $host 2>/dev/null)
        end
        if test -z "$token"; and type -q security
            set token (security find-generic-password -s jira-cli -a $login -w 2>/dev/null)
        end
    end

    if test -z "$token"
        echo "jira: API token not found" >&2
        echo "  tried: \$JIRA_API_TOKEN, ~/.netrc (machine $host), keychain (service 'jira-cli', account '$login')" >&2
        echo "  fixes:" >&2
        echo "    set -x JIRA_API_TOKEN <token>" >&2
        echo "    # or add to ~/.netrc:  machine $host login $login password <token>" >&2
        return 1
    end

    printf '%s\t%s\t%s\n' $server $login $token
end
