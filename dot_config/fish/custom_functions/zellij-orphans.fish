function zellij-orphans --description "Detect (and kill) orphaned zellij servers left behind by client respawn races"
    # When a client reconnects to a wedged server (fd exhaustion etc.) it
    # spawns a fresh server on the same socket path; the old one keeps
    # running detached forever (PPID=1, nobody reaps it).
    # Discriminator (validated on multiple incidents): the live server holds
    # multiple fds on its socket (listen + accepted connections), an orphan
    # holds only the single original one. A server whose socket file is gone
    # is also an orphan.
    argparse kill -- $argv
    or return 1

    set -l pids
    set -l socks
    for line in (ps -Ao pid=,command=)
        set -l m (string match -r '^\s*(\d+)\s+\S*zellij\S*\s+--server\s+(\S+)$' -- $line)
        test -n "$m"; or continue
        set -a pids $m[2]
        set -a socks $m[3]
    end
    if test (count $pids) -eq 0
        echo "No zellij servers running"
        return 0
    end

    set -l orphans
    set -l orphan_safe
    for i in (seq (count $pids))
        set -l pid $pids[$i]
        set -l sock $socks[$i]
        set -l session (path basename -- $sock)
        set -l age (ps -o etime= -p $pid | string trim)

        set -l verdict live
        if not test -S $sock
            set verdict orphan
        else
            set -l own_fds (lsof $sock 2>/dev/null | awk -v p=$pid 'NR>1 && $2==p {n++} END {print n+0}')
            set -l max_other 0
            for j in (seq (count $pids))
                test $socks[$j] = $sock -a $pids[$j] != $pid; or continue
                set -l other (lsof $sock 2>/dev/null | awk -v p=$pids[$j] 'NR>1 && $2==p {n++} END {print n+0}')
                test $other -gt $max_other; and set max_other $other
            end
            if test $own_fds -le 1 -a $max_other -ge 2
                set verdict orphan
            end
        end

        if test $verdict = live
            printf "  live    %-9s pid=%-7s up %s\n" $session $pid $age
            continue
        end

        # safety: refuse auto-kill if ANY descendant (not just direct children)
        # is more than an idle shell / hwatch — a pane fish can hold a claude
        # grandchild that dies with the server
        set -l safe 1
        set -l descendants
        set -l queue (pgrep -P $pid)
        while test (count $queue) -gt 0
            set -l cur $queue[1]
            set -e queue[1]
            set -a descendants $cur
            set -a queue (pgrep -P $cur)
        end
        for k in $descendants
            set -l cmd (ps -o command= -p $k | string trim)
            test -n "$cmd"; or continue
            string match -qr '^(-?fish|fish$|fish |hwatch)' -- $cmd
            or begin
                set safe 0
                printf "  ⚠ orphan %-8s pid=%-7s descendant pid=%s runs: %s\n" $session $pid $k $cmd
            end
        end
        printf "  ORPHAN  %-9s pid=%-7s up %-12s descendants=%d %s\n" $session $pid $age (count $descendants) (test $safe -eq 1; and echo "(safe to kill)"; or echo "(HAS ACTIVE WORK — skipped)")
        set -a orphans $pid
        set -a orphan_safe $safe
    end

    if test (count $orphans) -eq 0
        echo "No orphans detected"
        return 0
    end

    if not set -q _flag_kill
        echo
        echo "Run 'zellij-orphans --kill' to remove the safe ones"
        return 0
    end

    for i in (seq (count $orphans))
        test $orphan_safe[$i] -eq 1; or continue
        # SIGKILL directly: wedged servers ignore SIGTERM (observed repeatedly)
        kill -9 $orphans[$i]
        echo "killed $orphans[$i]"
    end
end
