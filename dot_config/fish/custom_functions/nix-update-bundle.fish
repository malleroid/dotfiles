function nix-update-bundle --description "Update flake.lock and report cache state"
    set -l dotfiles (chezmoi source-path 2>/dev/null)
    or set dotfiles ~/ghq/github.com/malleroid/dotfiles

    if not test -f $dotfiles/flake.lock
        echo "flake.lock not found at $dotfiles"
        return 1
    end

    pushd $dotfiles

    cp flake.lock flake.lock.bak
    echo "Running nix flake update..."
    nix flake update

    if cmp -s flake.lock flake.lock.bak
        echo "No changes to flake.lock."
        rm flake.lock.bak
        popd
        return 0
    end

    echo
    echo "Checking cache state..."
    set -l plan (nix build . --dry-run 2>&1)

    if string match -q "*will be built*" -- $plan
        echo "⚠ Cache miss detected. Full plan:"
        printf '  %s\n' $plan
        echo
        echo "Options:"
        echo "  Accept and build:   rm flake.lock.bak"
        echo "  Revert update:      mv flake.lock.bak flake.lock"
        echo "  Pin offender:       add a dedicated input in flake.nix"
    else
        echo "✓ All cached. Safe to commit."
        echo "  rm flake.lock.bak; git add flake.lock; git commit -m ':up: bump nixpkgs lockfile'"
    end

    popd
end
