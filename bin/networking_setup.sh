#!/bin/env bash
set -e

# installs networking packages
sudo pacman -Sy --needed --noconfirm - < networking_pkgs.txt

# enable and start networking services/symlinks
sudo systemctl enable iwd.service systemd-resolved.service
sudo systemctl start iwd.service systemd-resolved.service

# writes to iwd
echo "[General]
EnableNetworkingConfiguration=true

[Network]
NameResolvingService=systemd
" | sudo tee /etc/iwd/main.conf

# writes to modules-load
echo "wl" | sudo tee /etc/modules-load.d/wl.conf

printf "\n\nAll Done!\n"

