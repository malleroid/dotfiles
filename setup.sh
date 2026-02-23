#!/bin/sh

# homebrew install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo "eval $(/opt/homebrew/bin/brew shellenv)" >> "$HOME"/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# brew bundle
brew bundle

# mise install tools
mise install

# change shell
sudo sh -c "echo '/opt/homebrew/bin/fish' >> /etc/shells"
chsh -s /opt/homebrew/bin/fish

# fish setup
fish -c "curl -sL git.io/fisher | source && fisher update"

# gh extension
fish -c "gh extension install dlvhdr/gh-dash && gh extension install seachicken/gh-poi"

# ollama native install
curl -fsSL https://ollama.com/install.sh | sh

# claude code native install
curl -fsSL https://claude.ai/install.sh | sh
