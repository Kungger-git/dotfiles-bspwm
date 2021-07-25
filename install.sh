# install system packages
sudo pacman -Sy --noconfirm - < packages.txt

# install yay-git
git clone https://aur.archlinux.org/yay-git.git; cd yay-git/; makepkg -si --noconfirm; cd ..

# remove orphans and yay-git folder
sudo pacman -Rns --noconfirm $(pacman -Qtdq); rm -rf yay-git/

# install aur packages
yay -Sy --noconfirm - < aur.txt

# enable services
sudo systemctl enable iwd.service
sudo systemctl enable systemd-resolved.service

# make user dirs
xdg-user-dirs-update

# copy configs
cp -r dots/configs/* $HOME/.config/

# copy home dots
cp dots/.zshrc $HOME
cp dots/.vimrc $HOME
cp dots/.gitconfig $HOME
cp dots/.xinitrc $HOME

# install fonts for polybar
FDIR="$HOME/.local/share/fonts"
echo -e "\n[*] Installing fonts..."
if [[ -d "$FDIR" ]]; then
    cp -rf fonts/* "$FDIR"
else
    mkdir -p "$FDIR"
    cp -rf fonts/* "$FDIR"
fi

# install oh-my-zsh and change shell to zsh
curl -L http://install.ohmyz.sh | sh
sudo chsh -s /bin/zsh; chsh -s /bin/zsh

# clone zsh plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# install python3 pip
git clone https://github.com/KungPaoChick/arch-pip-setup.git ~/.pip-setup; cd ~/.pip-setup
bash setup.sh; cd; rm -rf ~/.pip-setup/; cd ~/arch-setup/