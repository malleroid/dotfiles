function __gwq_worktree_search -d 'Worktree search'
    gwq get -g | read select
    [ -n "$select" ]; and cd "$select"
    commandline -f repaint
end
