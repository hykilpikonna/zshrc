#!/usr/bin/env bash

# Install yay
pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay-bin.git /tmp/yay
cd /tmp/yay
makepkg -si
cd -
