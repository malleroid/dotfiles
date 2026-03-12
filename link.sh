#!/bin/sh

DOTFILES_DIR=$(cd "$(dirname "$0")" || exit; pwd)

ln -snfv "$DOTFILES_DIR"/gitui ~/.config
ln -snfv "$DOTFILES_DIR"/fish ~/.config
ln -snfv "$DOTFILES_DIR"/mise ~/.config
ln -snfv "$DOTFILES_DIR"/nvim ~/.config
ln -snfv "$DOTFILES_DIR"/serpl ~/.config
ln -snfv "$DOTFILES_DIR"/starship.toml ~/.config
ln -snfv "$DOTFILES_DIR"/wezterm ~/.config
ln -snfv "$DOTFILES_DIR"/.gitconfig ~/.gitconfig
ln -snfv "$DOTFILES_DIR"/.gitignore ~/.gitignore
ln -snfv "$DOTFILES_DIR"/.claude/CLAUDE.md ~/.claude/CLAUDE.md
ln -snfv "$DOTFILES_DIR"/.claude/settings.json ~/.claude/settings.json
ln -snfv "$DOTFILES_DIR"/.claude/skills ~/.claude/skills
ln -snfv "$DOTFILES_DIR"/.claude/agents ~/.claude/agents
ln -snfv "$DOTFILES_DIR"/.claude/hooks ~/.claude/hooks
mkdir -p ~/.copilot
ln -snfv "$DOTFILES_DIR"/copilot/mcp-config.json ~/.copilot/mcp-config.json
mkdir -p ~/.config/rails-mcp
ln -snfv "$DOTFILES_DIR"/rails-mcp/projects.yml ~/.config/rails-mcp/projects.yml
mkdir -p ~/.codex
ln -snfv "$DOTFILES_DIR"/codex/config.toml ~/.codex/config.toml
ln -snfv "$DOTFILES_DIR"/codex/AGENTS.md ~/.codex/AGENTS.md
ln -snfv "$DOTFILES_DIR"/.commit_template ~/.commit_template
