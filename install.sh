# install system packages
sudo pacman -Sy --noconfirm - < packages.txt

# install yay-git
git clone https://aur.archlinux.org/yay-git.git; cd yay-git/; makepkg -si --noconfirm; cd ..

# remove orphans and yay-git folder
sudo pacman -Rns --noconfirm $(pacman -Qtdq); rm -rf $HOME/yay-git/

# install aur packages
yay -Sy --noconfirm - < aur.txt

# make user dirs
xdg-user-dirs-update

# mkdirs
mkdir ~/.config/bspwm
mkdir ~/.config/sxhkd
mkdir ~/.config/picom
mkdir ~/.config/polybar

# copy examples
cp /usr/share/doc/bspwm/examples/bspwmrc ~/.config/bspwm/
cp /usr/share/doc/bspwm/examples/sxhkdrc ~/.config/sxhkd/
cp /usr/share/doc/picom/picom.conf.example ~/.config/picom/picom.conf
cp /etc/X11/xinit/xinitrc ~/.xinitrc

# install cool polybar themes
git clone https://github.com/adi1090x/polybar-themes.git ~/polybar-themes
cd ~/polybar-themes/; ./setup.sh; cd ~/arch-setup/

# install oh my zsh
curl -L http://install.ohmyz.sh | sh
sudo chsh -s /bin/zsh; chsh -s /bin/zsh

# clone zsh plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# install python3 pip
git clone https://github.com/KungPaoChick/arch-pip-setup.git ~/.pip-setup; cd ~/.pip-setup
bash setup.sh; cd; rm -rf ~/.pip-setup/; cd ~/arch-setup/
