if type -q ssh-add
    ssh-add -l >/dev/null 2>&1
    set -l agent_status $status

    if test $agent_status -ne 0; and type -q launchctl
        set -l launchd_sock (launchctl getenv SSH_AUTH_SOCK)

        # launchd mints a new agent socket path every boot, so the path must never be
        # cached. Adopt it only when the inherited socket is dead, to leave a live
        # forwarded agent alone.
        if test $agent_status -eq 2; and test -n "$launchd_sock"
            set -e SSH_AGENT_PID
            set -gx SSH_AUTH_SOCK $launchd_sock
            ssh-add -l >/dev/null 2>&1
            set agent_status $status
        end

        # Status 1 means the agent answers but holds no key. Loading only into launchd's
        # own socket keeps keychain keys out of a forwarded or third-party agent.
        if test $agent_status -eq 1; and test -n "$launchd_sock"; and test "$SSH_AUTH_SOCK" = "$launchd_sock"
            ssh-add --apple-load-keychain 2>/dev/null
        end
    end
end

# fish's `set` passes $status through untouched, so a failed probe above would otherwise
# leak out of this file and into the config.fish source loop.
true
