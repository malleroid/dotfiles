#!/bin/sh

# homebrew install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo "eval $(/opt/homebrew/bin/brew shellenv)" >> "$HOME"/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# brew bundle
brew bundle

# change shell
sudo sh -c "echo '/opt/homebrew/bin/fish' >> /etc/shells"
chsh -s /opt/homebrew/bin/fish

# rust install
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# fish setup
fish -c "curl -sL git.io/fisher | source && fisher update"

# gh extension
fish -c "gh extension install dlvhdr/gh-dash"
