function zellij-dump --description "Capture zellij state for post-mortem before logs rotate"
    # Zellij keeps its logs in $TMPDIR (volatile, 16MB rotation, only 1 old
    # generation). When a server wedges (e.g. Cmd+s hangs / fd exhaustion),
    # run this BEFORE restarting Ghostty or killing servers, otherwise the
    # evidence around the onset is lost.
    set -l dest ~/.local/state/zellij-dumps/(date +%Y%m%d-%H%M%S)
    mkdir -p $dest

    set -l zellij_tmp $TMPDIR/zellij-(id -u)

    # 1. Logs (most important: shared by all servers, rotates fast under error storms)
    cp $zellij_tmp/zellij-log/zellij.log* $dest/ 2>/dev/null

    # 2. Process state: servers, clients, orphans (PPID=1 servers with a
    #    socket owned by another pid are orphans)
    ps -Ao pid,ppid,lstart,etime,%cpu,rss,stat,command | grep -i zellij >$dest/ps-zellij.txt
    zellij list-sessions >$dest/sessions.txt 2>&1

    # 3. Full fd list per server process (fd exhaustion evidence dies with the process)
    for line in (ps -Ao pid=,command= | string match -r '.*zellij.*--server.*')
        set -l pid (string match -r '^\s*(\d+)' -- $line)[2]
        lsof -p $pid >$dest/lsof-$pid.txt 2>/dev/null
    end

    # 4. Socket dir (mtime tells which server is current) and plugin cache
    #    tree (instance dirs are named <plugin_id>-<client_id>)
    ls -laT $zellij_tmp/contract_version_1/ >$dest/sockets.txt 2>/dev/null
    ls -R ~/Library/Caches/org.Zellij-Contributors.Zellij >$dest/cache-tree.txt 2>/dev/null

    # 5. Environment
    date >$dest/env.txt
    zellij --version >>$dest/env.txt
    echo "ulimit -Sn: "(ulimit -Sn) >>$dest/env.txt
    sysctl kern.maxfiles kern.maxfilesperproc >>$dest/env.txt

    echo "dumped to $dest"
    ls -la $dest
end
