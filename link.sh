#!/bin/sh

DOTFILES_DIR=$(cd "$(dirname "$0")" || exit; pwd)

ln -snfv "$DOTFILES_DIR"/gitui ~/.config
ln -snfv "$DOTFILES_DIR"/fish ~/.config
ln -snfv "$DOTFILES_DIR"/mise ~/.config
mkdir -p ~/.config/mcpm
ln -snfv "$DOTFILES_DIR"/mcpm/servers.json ~/.config/mcpm/servers.json
ln -snfv "$DOTFILES_DIR"/mcpm/config.json ~/.config/mcpm/config.json
ln -snfv "$DOTFILES_DIR"/nvim ~/.config
ln -snfv "$DOTFILES_DIR"/serpl ~/.config
ln -snfv "$DOTFILES_DIR"/starship.toml ~/.config
ln -snfv "$DOTFILES_DIR"/wezterm ~/.config
ln -snfv "$DOTFILES_DIR"/.gitconfig ~/.gitconfig
ln -snfv "$DOTFILES_DIR"/.gitignore ~/.gitignore
ln -snfv "$DOTFILES_DIR"/.claude/CLAUDE.md ~/.claude/CLAUDE.md
ln -snfv "$DOTFILES_DIR"/.claude/settings.json ~/.claude/settings.json
ln -snfv "$DOTFILES_DIR"/.claude/commands ~/.claude/commands
ln -snfv "$DOTFILES_DIR"/.commit_template ~/.commit_template
