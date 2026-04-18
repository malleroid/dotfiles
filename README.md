# dotfiles

## Overview
- Personal dotfiles managed by [chezmoi](https://www.chezmoi.io/) with Nix (CLI packages) and Homebrew (macOS GUI apps).
- Targets: macOS, Ubuntu, Arch Linux, devcontainers, EC2.
- Defaults: fish shell + Starship prompt, Neovim editor, Ghostty terminal + Zellij multiplexer.

## Setup

One command to bootstrap a new machine:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply malleroid/dotfiles
```

This will:
1. Install chezmoi to `./bin/` and `exec` it directly (PATH not required)
2. Clone this repo and apply dotfiles
3. Run setup scripts (Nix, Homebrew, packages, shell config, etc.)

For ephemeral environments (devcontainers, EC2):

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --one-shot --promptString 'Environment type (full/ephemeral)=ephemeral' malleroid/dotfiles
```

To install chezmoi permanently to `~/.local/bin/`:

```sh
sh -c "$(curl -fsLS get.chezmoi.io/lb)"
```

## Package Management

| What | Manager | File |
|------|---------|------|
| CLI tools (70 packages) | Nix | `nix-packages.txt` |
| macOS GUI apps (57 casks) | Homebrew | `Brewfile.casks` |
| Language runtimes & dev tools | mise | `dot_config/mise/config.toml` |

## Layout

```
dotfiles/
├── .chezmoi.toml.tmpl          # chezmoi config (env_type prompt)
├── .chezmoiignore              # files excluded from deployment
├── nix-packages.txt            # CLI packages for Nix
├── Brewfile.casks              # macOS GUI apps for Homebrew
├── dot_gitconfig                # → ~/.gitconfig
├── dot_gitignore                # → ~/.gitignore
├── dot_commit_template          # → ~/.commit_template
├── dot_config/                  # → ~/.config/
│   ├── fish/                    #   fish shell (3 files templated for OS)
│   ├── nvim/                    #   Neovim
│   ├── mise/                    #   mise runtime manager
│   ├── ghostty/                 #   Ghostty terminal
│   ├── zellij/                  #   Zellij multiplexer
│   ├── starship.toml            #   Starship prompt
│   ├── nix/                     #   Nix config (experimental features)
│   ├── gitui/, serpl/           #   TUI tools
│   └── rails-mcp/              #   Rails MCP server
├── dot_claude/                  # → ~/.claude/
│   ├── agents/                  #   sub-agent definitions
│   ├── hooks/                   #   git guard hooks (executable_)
│   └── symlink_skills.tmpl      #   → ~/.agents/skills
├── dot_agents/skills/           # → ~/.agents/skills/
├── dot_copilot/                 # → ~/.copilot/
├── dot_codex/                   # → ~/.codex/ (create_ prefix: no overwrite)
└── run_*                        # chezmoi setup scripts (9 total)
```

## Operations

- **Add a Nix package**: Add to `nix-packages.txt`, then `chezmoi apply` (triggers `run_onchange`).
- **Add a macOS cask**: Add to `Brewfile.casks`, then `chezmoi apply`.
- **Update dotfiles**: Edit `dot_*` files, then `chezmoi apply` to deploy.
- **Sync from home**: `chezmoi re-add <file>` to pull changes back from `~/`.
- **Quick checks**: `exec fish` to reload shell; `chezmoi diff` to preview changes.
