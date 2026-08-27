# Run `once_per_boot_tasks` in the first interactive shell after a machine boot.
#
# The tasks run in the foreground, just before the first prompt is drawn, so the shell
# is fully initialized by then. Every other shell in the same boot skips them. The boot
# is claimed BEFORE the tasks run, so a failed or interrupted run is not retried
# automatically -- call `once_per_boot_tasks` by hand.
#
# Setup (per machine):
#   cp ~/.config/fish/once_per_boot.local.fish.example \
#      ~/.config/fish/once_per_boot.local.fish
#   $EDITOR ~/.config/fish/once_per_boot.local.fish

if test -f "$HOME/.config/fish/once_per_boot.local.fish"
    source "$HOME/.config/fish/once_per_boot.local.fish"
end

function __once_per_boot_claim --description 'Claim this boot; fail if another shell already claimed it'
    set -l state_home "$XDG_STATE_HOME"
    test -n "$state_home"; or set state_home "$HOME/.local/state"
    set -l state "$state_home/once-per-boot"

    set -l boot_id (sysctl -n kern.boottime | string match -rg '\bsec = (\d+)')
    test -n "$boot_id"; or return 1

    mkdir -p "$state"; or return 1
    set -l claim "$state/boot-$boot_id"
    mkdir "$claim" 2>/dev/null; or return 1

    for stale in $state/boot-*
        test "$stale" = "$claim"; and continue
        rm -rf "$stale"
    end
end

function __once_per_boot_run --on-event fish_prompt --description 'Run once_per_boot_tasks in the first shell after a boot'
    functions --erase __once_per_boot_run
    functions -q once_per_boot_tasks; or return
    __once_per_boot_claim; and once_per_boot_tasks
end
