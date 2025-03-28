#!/usr/bin/env bash

set -e

doppler secrets substitute home/.env.template --project ansible --config dev >home/zsh/.env
# Install link of home files
rm -rf ~/.fonts ~/.tmux ~/.dotenv ~/scripts ~/zsh ~/.bashrc ~/.tmux.conf ~/.zprofile ~/.zshrc ~/.DS_Store ~/.env

sudo stow -t ~ home

# Install config files
rm ~/.config/nvim ~/.config/gh ~/.config/tmuxinator
mkdir -p .config && cd .config
mkdir -p ~/.config/nvim && stow -t ~/.config/nvim nvim
mkdir -p ~/.config/gh && stow -t ~/.config/gh gh
mkdir -p ~/.config/tmuxinator && stow -t ~/.config/tmuxinator tmuxinator
mkdir -p .config && cd .config && mkdir -p ~/.config/sketchybar && stow -t ~/.config/sketchybar sketchybar

ln -s ~/config/.config/starship.toml ~/.config/starship.toml
