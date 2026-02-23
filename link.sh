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
mkdir -p ~/.codex
# Keep machine-specific trust/project entries local in ~/.codex/config.toml.
# Seed from dotfiles only when missing (or when previously symlinked).
if [ -L ~/.codex/config.toml ]; then
  rm ~/.codex/config.toml
fi
if [ ! -f ~/.codex/config.toml ]; then
  cp "$DOTFILES_DIR"/codex/config.toml ~/.codex/config.toml
  chmod 600 ~/.codex/config.toml
fi
ln -snfv "$DOTFILES_DIR"/.commit_template ~/.commit_template
