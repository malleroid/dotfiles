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
