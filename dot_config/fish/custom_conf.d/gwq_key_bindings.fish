# fzf-style jump to gwq worktrees (gwq counterpart of the ghq plugin's Ctrl-G)
# Ctrl-Q historically collides with terminal flow control (XON), but fish
# disables flow control on interactive startup, so the key reaches fish.
bind ctrl-q __gwq_worktree_search
if bind -M insert >/dev/null 2>&1
    bind -M insert ctrl-q __gwq_worktree_search
end
