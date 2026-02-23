# dotfiles

## Overview
- Personal dotfiles for macOS with Homebrew, fish shell, and Neovim.
- Bootstrap with `setup.sh`, then symlink into `$HOME`/`~/.config` via `link.sh`.
- Defaults: fish shell + Starship prompt, Neovim editor, WezTerm terminal.

## Setup
1. Clone  
   `git clone git@github.com:malleroid/dotfiles.git ~/dotfiles && cd ~/dotfiles`
2. Install base tools (Homebrew, Brew Bundle, mise, fish, etc.)  
   `./setup.sh`  
   - Installs Homebrew and all packages from `Brewfile`.  
   - Runs `mise install` to align tool versions.  
   - Switches the login shell to `/opt/homebrew/bin/fish`.  
   - Installs fish plugins via fisher and GitHub CLI extensions.  
   - Requires `sudo`; follow the prompts.
3. Link dotfiles  
   `./link.sh`  
   - Creates symlinks under `~/.config` and the home directory. Existing files may be overwritten.
4. Reload shell (log in again or `exec fish`) to apply settings.

## Layout
- `setup.sh` / `link.sh`: Bootstrap and symlink scripts.
- `Brewfile`: Brew-managed CLI/GUI packages.
- `fish/`: Shell config (`config.fish`, custom functions, fisher plugins).
- `nvim/`: Neovim config.
- `starship.toml`: Prompt config.
- `wezterm/`: WezTerm config.
- `gitui/`, `mise/`, `serpl/`, `mcpm/`, `codex/`: Tool-specific configs.
- `.gitconfig`, `.gitignore`, `.commit_template`: Git settings.
- `.claude/`: Claude-related settings.

## Operations
- Package updates: run `brew bundle dump --force` to refresh `Brewfile`, then commit. Use `mise install` / `mise upgrade` to sync tool versions.
- Adding configs: place new tool config in `$HOME/.config`, then add its symlink step to `link.sh`.
- Codex config: `codex/config.toml` is the shared base. `link.sh` seeds `~/.codex/config.toml` only when missing, so machine-specific `[projects]` trust entries stay local.
- Codex agents instruction: `codex/AGENTS.md` is symlinked to `~/.codex/AGENTS.md`.
- Personal info: override Git `user.name` / `user.email` locally as needed.
- Quick checks: `exec fish` to reload shell config; `nvim --headless "+checkhealth" +qall` to verify Neovim setup.
