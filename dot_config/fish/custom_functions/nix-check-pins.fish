function nix-check-pins --description "Check if pinned nixpkgs inputs can be merged back to main"
    set -l dotfiles (chezmoi source-path 2>/dev/null)
    or set dotfiles ~/ghq/github.com/malleroid/dotfiles

    if not test -f $dotfiles/flake.lock
        echo "flake.lock not found at $dotfiles"
        return 1
    end

    pushd $dotfiles

    set -l pinned (jq -r '.nodes.root.inputs | keys[] | select(. != "nixpkgs")' flake.lock)

    if test (count $pinned) -eq 0
        echo "No pinned inputs other than main nixpkgs."
        popd
        return 0
    end

    set -l main_url "github:NixOS/nixpkgs/nixpkgs-unstable"

    for input in $pinned
        set -l rev (jq -r ".nodes.\"$input\".locked.rev" flake.lock | string sub -l 12)
        echo "Checking $input (currently @ $rev)..."

        set -l result (nix build .#default --override-input $input $main_url --dry-run 2>&1)

        if string match -q "*will be built*" -- $result
            echo "  ⚠ Still needs builds with main nixpkgs. Keep the pin."
        else
            echo "  ✓ Mergeable. Update flake.nix to use 'pkgs.<pkg>' and drop the '$input' input."
        end
    end

    popd
end
