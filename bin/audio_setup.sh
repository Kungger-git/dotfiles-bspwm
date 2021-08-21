#!/bin/env bash
set -e

# installs audio packages
sudo pacman -Sy --needed --noconfirm - < audio_pkgs.txt
