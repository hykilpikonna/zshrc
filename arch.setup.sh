#!/usr/bin/env bash

# Stop on error
set -e

# Install yay
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay-bin.git /tmp/yay
cd /tmp/yay
makepkg -si
cd -
