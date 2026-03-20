# Migration Guide: link.sh + setup.sh → chezmoi + Nix

Existing machines using the old `link.sh` / `setup.sh` setup need manual migration.

## Prerequisites

- Pull the latest `feature/chezmoi-nix-migration` branch (or `master` after merge)

## Steps

### 1. Remove broken symlinks

After pulling, the old symlink targets (e.g., `fish/`, `.gitconfig`) no longer exist.
The symlinks in `$HOME` are now broken. chezmoi will replace them with real files on apply.

One exception: `~/.codex/config.toml` uses the `create_` prefix (won't overwrite existing files).
If it's a broken symlink, remove it first:

```sh
rm ~/.codex/config.toml
```

### 2. Install chezmoi

```sh
sh -c "$(curl -fsLS get.chezmoi.io/lb)"
```

### 3. Initialize and apply

```sh
~/.local/bin/chezmoi init --source ~/ghq/github.com/malleroid/dotfiles --apply
```

This will:
- Deploy all dotfiles (replacing broken symlinks with real files)
- Run setup scripts (Nix install, packages, shell config, etc.)

### 4. Known issue: Nix not in PATH after install

The Nix installer (`run_once_before_01`) installs Nix, but the current shell may not
have `nix` in PATH yet. The `run_onchange_after_10-nix-packages` script will skip
with "Nix not installed, skipping".

**Fix**: After the initial apply, restart your shell and run:

```sh
chezmoi apply
```

Or install packages manually:

```sh
nix profile add nixpkgs#bat nixpkgs#eza nixpkgs#fd ...
```

See `nix-packages.txt` for the full list.

### 5. Remove Homebrew CLI packages

After verifying Nix packages work:

```sh
# Uninstall all CLI formulas that are now in Nix
brew uninstall aichat tgpt httpie ... (see nix-packages.txt for full list)

# Also remove tools that were dropped
brew uninstall dblab harlequin jiratui pieces-cli specify pug qman progressline x-cmd rails-mcp-server

# Clean up
brew autoremove
brew cleanup
```

### 6. Switch chezmoi from Homebrew to self-bootstrap

```sh
sh -c "$(curl -fsLS get.chezmoi.io/lb)"
brew uninstall chezmoi
```

### 7. Fix login shell (Homebrew fish → Nix fish)

The old setup set `/opt/homebrew/bin/fish` as the login shell via `chsh`.
After migration to Nix, this path no longer exists and causes terminal launch failures (e.g., Ghostty).

```sh
# Add Nix fish to /etc/shells
echo ~/.nix-profile/bin/fish | sudo tee -a /etc/shells

# Change login shell
chsh -s ~/.nix-profile/bin/fish
```

After this, restart your terminal or log out/in.

### 8. Verify

```sh
chezmoi diff          # should show no diff
fish                  # should start without errors
which bat             # should point to ~/.nix-profile/bin/bat
ls -la ~/.claude/skills  # should be symlink → ~/.agents/skills
```
