#!/bin/sh

DOTFILES_DIR=$(cd "$(dirname "$0")" || exit; pwd)

ln -snfv "$DOTFILES_DIR"/gitui ~/.config
ln -snfv "$DOTFILES_DIR"/fish ~/.config
ln -snfv "$DOTFILES_DIR"/.gitconfig ~/.gitconfig
ln -snfv "$DOTFILES_DIR"/.gitignore ~/.gitignore
ln -snfv "$DOTFILES_DIR"/.commit_template ~/.commit_template
