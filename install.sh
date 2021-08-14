#!/bin/env bash

# replaces default pacman.conf with better one
sudo cp -f systemfiles/pacman.conf /etc/

# full upgrade
sudo pacman -Syy; sudo pacman -Syu --noconfirm

# install system packages
sudo pacman -Sy --needed --noconfirm - < packages.txt
sudo pacman -R --noconfirm i3-wm

# install yay-git
git clone https://aur.archlinux.org/yay-git.git; cd yay-git/; makepkg -si --noconfirm; cd ..

# remove orphans and yay-git folder
sudo pacman -Rns --noconfirm $(pacman -Qtdq); rm -rf yay-git/

# install aur packages
yay -Sy --noconfirm - < aur.txt

# enable services
sudo systemctl enable iwd.service systemd-resolved.service betterlockscreen@$USER.service lxdm-plymouth.service

# mkinitcpio configuration
sudo cp -f systemfiles/mkinitcpio.conf /etc/

# touchpad configuration
sudo cp -f systemfiles/02-touchpad-ttc.conf /etc/X11/xorg.conf.d/

# scripts
sudo cp -f scripts/* /usr/local/bin/

# Adds pw_feedback to sudoers.d
sudo cp -f systemfiles/01_pw_feedback /etc/sudoers.d/

# writes grub menu entries, copies grub, themes and updates it
sudo bash -c "cat >> '/etc/grub.d/40_custom' <<-EOF

menuentry 'Reboot System' --class restart {
    reboot
}

menuentry 'Shutdown System' --class shutdown {
    halt
}

EOF"
sudo cp -f grubcfg/grubd/* /etc/grub.d/
sudo cp -f grubcfg/grub /etc/default/
sudo cp -rf grubcfg/themes/default /boot/grub/themes/
sudo grub-mkconfig -o /boot/grub/grub.cfg

# plymouth
sudo cp -f lxdm/lxdm.conf /etc/lxdm/
sudo cp -rf lxdm/lxdm-theme/* /usr/share/lxdm/themes/
sudo plymouth-set-default-theme -R colorful_loop
sudo mkinitcpio -p linux

# write to iwd
echo "[General]
EnableNetworkConfiguration=true

[Network]
NameResolvingService=systemd
" | sudo tee /etc/iwd/main.conf

# write to modules
echo "wl" | sudo tee /etc/modules-load.d/wl.conf

# make user dirs
xdg-user-dirs-update

# copy configs
cp -r dots/configs/* $HOME/.config/

# installs oh-my-zsh and changes shell to zsh
curl -L http://install.ohmyz.sh | sh
sudo chsh -s /bin/zsh; chsh -s /bin/zsh

# copy home dots
cp dots/.zshrc $HOME
cp dots/.vimrc $HOME
cp dots/.gitconfig $HOME
cp dots/.xinitrc $HOME
cp dots/.gtkrc-2.0 $HOME
cp dots/.hushlogin $HOME
cp dots/.fehbg $HOME
cp dots/.dmrc $HOME
cp -rf dots/.ncmpcpp $HOME
cp -rf dots/.mpd $HOME

# copy wallpapers to /usr/share/backgrounds/
sudo cp -rf wallpapers /usr/share/backgrounds/

# copy songs
cp songs/* $HOME/Music

# install fonts for polybar
FDIR="$HOME/.local/share/fonts"
echo -e "\n[*] Installing fonts..."
if [[ -d "$FDIR" ]]; then
    cp -rf fonts/* "$FDIR"
else
    mkdir -p "$FDIR"
    cp -rf fonts/* "$FDIR"
fi

# clone zsh plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# last orphan delete
sudo pacman -Rns --noconfirm $(pacman -Qtdq)
