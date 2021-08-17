#!/bin/env bash
set -e

# copies pacman.conf and mkinitcpio.conf
sudo cp -f systemfiles/pacman.conf \
           systemfiles/mkinitcpio.conf /etc/

# Adds pw_feedback to sudoers.d
sudo cp -f systemfiles/01_pw_feedback /etc/sudoers.d/

reset
echo 'm     m mmmmmm m        mmm   mmmm  m    m mmmmmm'; sleep 0.2
echo '#  #  # #      #      m"   " m"  "m ##  ## #'; sleep 0.2
echo '" #"# # #mmmmm #      #      #    # # ## # #mmmmm'; sleep 0.2
echo ' ## ##" #      #      #      #    # # "" # #'; sleep 0.2
echo ' #   #  #mmmmm #mmmmm  "mmm"  #mm#  #    # #mmmmm'; sleep 3

# full upgrade
sudo pacman -Syy; sudo pacman -Syu --noconfirm

# install system packages
sudo pacman -Sy --needed --noconfirm - < packages.txt

# install yay-git
#git clone https://aur.archlinux.org/yay-git.git; cd yay-git/; makepkg -si --noconfirm; cd ..; rm -rf yay-git/

# install aur packages
yay -Sy --needed --noconfirm - < aur.txt

# enable services
sudo systemctl enable iwd.service systemd-resolved.service lxdm-plymouth.service

# start couple services
sudo systemctl start iwd.service systemd-resolved.service

# touchpad configuration
sudo cp -f systemfiles/02-touchpad-ttc.conf /etc/X11/xorg.conf.d/

# scripts
sudo cp -f scripts/* /usr/local/bin/

# copy wallpapers to /usr/share/backgrounds/
sudo cp -rf wallpapers /usr/share/backgrounds/

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

# installs oh-my-zsh and changes shell to zsh
curl -L http://install.ohmyz.sh | sh
sudo chsh -s /bin/zsh; chsh -s /bin/zsh

# copy home dots
cp -rf dots/.zshrc    \
       dots/.vimrc    \
       dots/.xinitrc  \
       dots/.hushlogin\
       dots/.gtkrc-2.0\
       dots/.gitconfig\
       dots/.fehbg    \
       dots/.dmrc     \
       dots/.ncmpcpp/ \
       dots/.mpd/ $HOME
       
cp -rf configs/* $HOME/.config/

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

# last orphan delete and cache delete
sudo pacman -Rns --noconfirm $(pacman -Qtdq); sudo pacman -Sc --noconfirm; yay -Sc --noconfirm

# final
clear

read -p "$USER!, Reboot Now? (Required) [Y/n] " reb
if [[ "$reb" == "" || "$reb" == "Y" || "$reb" == "y" ]]; then
    sudo reboot now
else
    printf "\nAbort!\n"
fi
