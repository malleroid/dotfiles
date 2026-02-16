#!/bin/sh

DOTFILES_DIR=$(cd "$(dirname "$0")" || exit; pwd)

ln -snfv "$DOTFILES_DIR"/gitui ~/.config
ln -snfv "$DOTFILES_DIR"/fish ~/.config
ln -snfv "$DOTFILES_DIR"/mise ~/.config
mkdir -p ~/.config/mcpm
ln -snfv "$DOTFILES_DIR"/mcp/mcpm/servers.json ~/.config/mcpm/servers.json
ln -snfv "$DOTFILES_DIR"/mcp/mcpm/config.json ~/.config/mcpm/config.json
ln -snfv "$DOTFILES_DIR"/nvim ~/.config
ln -snfv "$DOTFILES_DIR"/serpl ~/.config
ln -snfv "$DOTFILES_DIR"/starship.toml ~/.config
ln -snfv "$DOTFILES_DIR"/wezterm ~/.config
ln -snfv "$DOTFILES_DIR"/.gitconfig ~/.gitconfig
ln -snfv "$DOTFILES_DIR"/.gitignore ~/.gitignore
ln -snfv "$DOTFILES_DIR"/.claude/CLAUDE.md ~/.claude/CLAUDE.md
ln -snfv "$DOTFILES_DIR"/.claude/settings.json ~/.claude/settings.json
ln -snfv "$DOTFILES_DIR"/.claude/commands ~/.claude/commands
ln -snfv "$DOTFILES_DIR"/.claude/agents ~/.claude/agents
ln -snfv "$DOTFILES_DIR"/.claude/hooks ~/.claude/hooks
mkdir -p ~/.claude/plugins
ln -snfv "$DOTFILES_DIR"/.claude/plugins/installed_plugins.json ~/.claude/plugins/installed_plugins.json
ln -snfv "$DOTFILES_DIR"/.claude/plugins/known_marketplaces.json ~/.claude/plugins/known_marketplaces.json
ln -snfv "$DOTFILES_DIR"/.commit_template ~/.commit_template
