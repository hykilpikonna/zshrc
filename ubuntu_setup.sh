#!/bin/bash
# Automatically setup ubuntu

# Install essential packages
apt update
apt install curl git net-tools -y

# Add ssh keys
mkdir ~/.ssh
curl -L https://github.com/Hykilpikonna.keys > ~/.ssh/authorized_keys

# Install zsh
apt install zsh -y
chsh -s /bin/zsh

# Install zshrc
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Hykilpikonna/zshrc/HEAD/fastinstall.sh)"

# Install shadowsocks
apt install shadowsocks-libev -y
git clone https://github.com/hykilpikonna/HyDEV-Proxy
mkdir /etc/shadowsocks-libev
cp -f ./HyDEV-Proxy/ss-server.json /etc/shadowsocks-libev/hydev.json
systemctl stop shadowsocks-libev
systemctl disable shadowsocks-libev
systemctl start shadowsocks-libev-server@hydev.service
systemctl enable shadowsocks-libev-server@hydev.service
