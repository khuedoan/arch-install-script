#!/bin/bash

install_dotfiles() {
    REPO="https://github.com/khuedoan/dotfiles.git"
    GITDIR=$HOME/.dotfiles/

    git clone --bare $REPO $GITDIR

    dotfiles() {
        /usr/bin/git --git-dir=$GITDIR --work-tree=$HOME $@
    }

    if ! dotfiles checkout; then
        echo "All of the above files will be deleted, are you sure? (y/N) "
        read -r response
        if [ "$response" = "y" ] || [[ "$@" == *"-y"* ]]; then
            dotfiles checkout 2>&1 | grep -E "^\s+" | sed -e 's/^[ \t]*//' | xargs -d "\n" -I {} rm -v {}
            dotfiles checkout
            dotfiles submodule update --init --recursive
            dotfiles config status.showUntrackedFiles no
        else
            rm -rf $GITDIR
            echo "Installation cancelled"
            exit 1
        fi
    else
        dotfiles config status.showUntrackedFiles no
    fi

    wallpapers_dir=$HOME/Pictures/Wallpapers
    mkdir -p $wallpapers_dir
    curl https://i.imgur.com/C3tCYsp.jpg > $wallpapers_dir/OneDarkBlur.jpg
}

install_aur_helper() {
    git clone https://aur.archlinux.org/trizen.git
    cd trizen
    makepkg -si --noconfirm
    cd ..
    rm -rf trizen
}

install_core_packages() {
    sudo pacman --noconfirm --needed -S alsa-utils arandr autorandr bc bspwm dunst feh firefox fzf git libnotify light maim npm playerctl sxhkd translate-shell ttf-dejavu wmctrl xautolock xcape xclip xdotool xorg-server xorg-setxkbmap xorg-xinit xorg-xrandr xorg-xsetroot xss-lock
    trizen --noconfirm --needed -S mons nerd-fonts-source-code-pro picom-git polybar

    # Add user to video group to adjust backlight
    sudo usermod -aG video $USER

    # st
    git clone https://github.com/khuedoan/st
    cd st
    sudo make clean install && sudo make clean
    cd ..
    rm -rf st

    # dmenu
    git clone https://github.com/khuedoan/dmenu
    cd dmenu
    sudo make clean install && sudo make clean
    cd ..
    rm -rf dmenu

    # slock
    git clone https://github.com/khuedoan/slock
    cd slock
    sudo make clean install && sudo make clean
    cd ..
    rm -rf slock
}

install_extra_packages() {
    sudo pacman --noconfirm --needed -S arc-gtk-theme aria2 glances gvfs htop man mpv noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra ntfs-3g papirus-icon-theme pcmanfm-gtk3 ranger thefuck tmux tree unrar unzip w3m xarchiver youtube-dl zathura zathura-pdf-mupdf zip
    trizen --noconfirm --needed -S ttf-ms-fonts ibus-bamboo
    dconf load /desktop/ibus/ < $HOME/.config/ibus/ibus.dconf
}

install_battery_saver() {
    sudo pacman --noconfirm --needed -S tlp powertop
    trizen --noconfirm --needed -S intel-undervolt
    sudo systemctl enable tlp.service
    sudo intel-undervolt apply
    sudo systemctl enable intel-undervolt.service
}

# TUI
if [ "$#" -eq 0 ]; then
    install_list=( $(whiptail --notags --title "Dotfiles" --checklist "Install list" 20 45 11 \
        install_dotfiles "All config files" on \
        install_aur_helper "AUR helper (trizen)" on \
        install_core_packages "Recommended packages" on \
        install_extra_packages "Extra packages" on \
        3>&1 1>&2 2>&3 | sed 's/"//g') )

    for install_function in "${install_list[@]}"; do
        $install_function
    done
# CLI
else
    if [ "$1" = "--minimal" ]; then
        cli_config_files=".aliases .config/nvim/init.vim .tmux.conf .zshrc"

        for file in $cli_config_files; do
            curl https://raw.githubusercontent.com/khuedoan/dotfiles/master/$file > $HOME/$file
        done
    elif [ "$1" = "--all" ]; then
        install_dotfiles
        install_aur_helper
        install_core_packages
        install_extra_packages
        install_battery_saver
    else
        if [[ "$@" == *"--dotfiles"* ]]; then
            install_dotfiles
        fi
        if [[ "$@" == *"--aur-helper"* ]]; then
            install_aur_helper
        fi
        if [[ "$@" == *"--packages"* ]]; then
            install_core_packages
        fi
        if [[ "$@" == *"--extra-packages"* ]]; then
            install_extra_packages
        fi
        if [[ "$@" == *"--battery-saver"* ]]; then
            install_battery_saver
        fi
    fi
fi
