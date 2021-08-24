#!/bin/env bash
set -e

set_color() {
    if [ -t 1 ]; then
        RED=$(printf '\033[31m')
        GREEN=$(printf '\033[32m')
        YELLOW=$(printf '\033[33m')
        BLUE=$(printf '\033[34m')
        BOLD=$(printf '\033[1m')
        RESET=$(printf '\033[m')
    else
        RED=""
        GREEN=""
        YELLOW=""
        BLUE=""
        BOLD=""
        RESET=""
    fi
}

main() {
    set_color
    
    # copies pacman.conf and mkinitcpio.conf
    sudo cp -f systemfiles/pacman.conf \
               systemfiles/mkinitcpio.conf /etc/

    # Adds pw_feedback to sudoers.d
    sudo cp -f systemfiles/01_pw_feedback /etc/sudoers.d/

    reset
    echo "${BLUE}m     m mmmmmm m        mmm   mmmm  m    m mmmmmm"; sleep 0.2
    echo '#  #  # #      #      m"   " m"  "m ##  ## #'; sleep 0.2
    echo '" #"# # #mmmmm #      #      #    # # ## # #mmmmm'; sleep 0.2
    echo ' ## ##" #      #      #      #    # # "" # #'; sleep 0.2
    echo ' #   #  #mmmmm #mmmmm  "mmm"  #mm#  #    # #mmmmm'; sleep 3
    echo "${RESET}"

    #
    # choose video driver
    #
    echo "${BOLD}##########################################################################${RESET}

${RED}1.) xf86-video-amdgpu     ${GREEN}2.) nvidia     ${BLUE}3.) xf86-video-intel${RESET}     4.) Skip

${BOLD}##########################################################################${RESET}"
    read -r -p "${YELLOW}${BOLD}[!] ${RESET}Choose your video card driver. ${YELLOW}(Default: 1)${RESET}: " vidri

    #
    # prompt for installing recommended packages
    #
    cat recommended_packages.txt
    read -p "${YELLOW}${BOLD}[!] ${RESET}Would you like to download these recommended system packages? [y/N] " recp

    #
    # select an aur helper to install
    #
    HELPER="yay"
    mkdir -p $HOME/.srcs

    echo "${BOLD}####################${RESET}

${RED}1.) yay     ${BLUE}2.) paru${RESET}

${BOLD}####################${RESET}"
    printf  "\n\n${YELLOW}${BOLD}[!] ${RESET}An AUR helper is essential to install required packages.\n"
    read -r -p "${YELLOW}${BOLD}[!] ${RESET}Select an AUR helper. ${YELLOW}(Default: yay)${RESET}: " sel    

    #
    # select a picom or picom fork
    #
    echo "${BOLD}##################################${RESET}

${RED}1.) picom   ${BLUE}2.) picom-jonaburg-git${RESET}

${BOLD}##################################${RESET}"
    read -r -p "${YELLOW}${BOLD}[!] ${RESET}Select your preferred compositor. ${YELLOW}(Default: 1)${RESET}: " comp

    #
    # prompt for installing recommended aur packages
    #
    cat recommended_aur.txt
    read -p "${YELLOW}${BOLD}[!] ${RESET}Would you like to download these recommended aur packages? [y/N] " reca

    # prompt to install networking tools and applications
    read -p "${YELLOW}${BOLD}[!] ${RESET}Would you like to install networking tools and applications? [y/N] " netw

    # prompt to install audio tools and applications
    read -p "${YELLOW}${BOLD}[!] ${RESET}Would you like to install audio tools and applications? [y/N] " aud

    #
    #
    # post prompt process
    #
    #
    case $vidri in
    [1])
            DRIVER='xf86-video-amdgpu xf86-video-ati xf86-video-fbdev' 
            ;;

    [2])
            DRIVER='nvidia nvidia-settings nvidia-utils'
            ;;

    [3])
            DRIVER='xf86-video-intel xf86-video-nouveau'
            ;;

    [4])
            DRIVER="xorg-xinit"
            ;;

    *)
            DRIVER='xf86-video-amdgpu xf86-video-ati xf86-video-fbdev' 
            ;;
    esac

    # full upgrade
    clear
    printf "${GREEN}${BOLD}[*] ${RESET}Performing System Upgrade and Installation...\n\n"
    sudo pacman -Syy; sudo pacman -Syu --noconfirm

    # installing selected video driver
    sudo pacman -S --needed --noconfirm $DRIVER

    # install system packages
    sudo pacman -S --needed --noconfirm - < packages.txt

    # recommended packages installer
    if [[ "$recp" == "" || "$recp" == "N" || "$recp" == "n" ]]; then
        printf "\n${RED}${BOLD}Abort!${RESET}\n"
        echo "${YELLOW}${BOLD}[!] ${RESET}You can install them later by doing: ${YELLOW}(sudo pacman -S - < recommended_packages.txt)${RESET}"
    else
        sudo pacman -S --needed --noconfirm - < recommended_packages.txt
    fi

    # aur installer
    if [ $sel -eq 2 ]; then
        HELPER="paru"
    fi

    if ! command -v $HELPER &> /dev/null; then
        printf "\n\n${YELLOW}${BOLD}[!] ${RESET}We'll be installing ${GREEN}${BOLD}$HELPER${RESET} then.\n\n"
            git clone https://aur.archlinux.org/$HELPER.git $HOME/.srcs/$HELPER
            (cd $HOME/.srcs/$HELPER/; makepkg -si --noconfirm)
    fi

    # install aur packages
    $HELPER -S --needed --noconfirm - < aur.txt

    # recommended aur packages installer
    if [[ "$reca" == "" || "$reca" == "N" || "$reca" == "n" ]]; then
        printf "\n${RED}Abort!${RESET}\n"
        echo "${YELLOW}${BOLD}[!] ${RESET}You can install them later by doing: ${YELLOW}($HELPER -S - < recommended_aur.txt)${RESET}"
    else
        $HELPER -S --needed --noconfirm - < recommended_aur.txt
    fi

    # enable services
    sudo systemctl enable lxdm-plymouth.service

    # touchpad configuration
    sudo cp -f systemfiles/02-touchpad-ttc.conf /etc/X11/xorg.conf.d/

    # scripts
    sudo cp -f scripts/* /usr/local/bin/

    # copy wallpapers to /usr/share/backgrounds/
    sudo mkdir -p /usr/share/backgrounds/
    sudo cp -rf wallpapers /usr/share/backgrounds/

    # writes grub menu entries, copies grub, themes and updates it
    sudo bash -c "cat >> '/etc/grub.d/40_custom' <<-EOF

    menuentry 'Reboot System' --class restart {
        reboot
    }

    menuentry 'Shutdown System' --class shutdown {
        halt
    }"
    sudo cp -f grubcfg/grubd/* /etc/grub.d/
    sudo cp -f grubcfg/grub /etc/default/
    sudo cp -rf grubcfg/themes/default /boot/grub/themes/
    sudo grub-mkconfig -o /boot/grub/grub.cfg

    # plymouth
    sudo cp -f lxdm/lxdm.conf /etc/lxdm/
    sudo cp -rf lxdm/lxdm-theme/* /usr/share/lxdm/themes/
    sudo plymouth-set-default-theme -R arch10

    # make user dirs
    xdg-user-dirs-update

    # networking tools and applications installer
    if [[ "$netw" == "" || "$netw" == "N" || "$netw" == "n" ]]; then
        printf "\n${RED}Abort!${RESET}\n"
        echo "${YELLOW}${BOLD}[!] ${RESET}You can find the networking setup script in the bin folder."
    else
        (cd bin/; ./networking_setup.sh)
    fi

    # audio tools and applications installer
    if [[ "$aud" == "" || "$aud" == "N" || "$aud" == "n" ]]; then
        printf "\n${RED}Abort!${RESET}\n"
        echo "${YELLOW}${BOLD}[!] ${RESET}You can find the audio setup script in the bin folder."
    else
        (cd bin/; ./audio_setup.sh)
    fi

    # installs oh-my-zsh and changes shell to zsh
    curl -L http://install.ohmyz.sh | sh
    chsh -s /bin/zsh

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

    # install selected compositor
    case $comp in
    [1])
            sudo pacman -S --needed --noconfirm picom &&
            cp -r compositors/picom-default/ $HOME/.config/picom
            ;;
    [2])
            $HELPER -S --needed --noconfirm picom-jonaburg-git &&
            cp -r compositors/picom-jonaburg/ $HOME/.config/picom
            ;;
    *)
            sudo pacman -S --needed --noconfirm picom &&
            cp -r compositors/picom-default/ $HOME/.config/picom
            ;;
    esac

    # copy songs
    cp songs/* $HOME/Music

    # install fonts for polybar
    FDIR="$HOME/.local/share/fonts"
    echo -e "\n${GREEN}${BOLD}[*] ${RESET}Installing fonts..."
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
    sudo pacman -Rns --noconfirm $(pacman -Qtdq); sudo pacman -Sc --noconfirm; $HELPER -Sc --noconfirm; sudo pacman -R --noconfirm i3-wm

    # final
    rm -rf $HOME/.srcs/$HELPER
    clear

    read -p "${GREEN}$USER!${RESET}, Reboot Now? ${YELLOW}(Required)${RESET} [Y/n] " reb
    if [[ "$reb" == "" || "$reb" == "Y" || "$reb" == "y" ]]; then
        sudo reboot now
    else
        printf "\n${RED}Abort!${RESET}\n"
    fi
}

main "@"
