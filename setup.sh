#!/bin/bash

# the location of here
HERE=`pwd`
relative_location=`dirname $0`

# add ppa by this
PPA=$HERE/res/ppa/ppa.sh
# my vim config
VIM=$HERE/res/vim/.vimrc
# my zsh config
ZSH=$HERE/res/zsh/zshrc
# my ss config
SS=$HERE/res/shadowsocks/shadowsocks.json
# applications will be installed
APPS=$HERE/res/apps/apps
# fonts in there
FONTS=$HERE/res/font/Monaco
# theme
THEME=$HERE/res/themes/Ambiance_Mac
# background
BACKGROUND=$HERE/res/background/*
# vscode
VS_CODE=$HERE/res/vscode/*
# log wil be write into this file
LOGS=$HERE/setup_log


# clear log
echo "" > $LOGS


## print log
print_log()
{
    echo -e  "\033[0;31;1m LOGS: $1  \033[0m"
    echo LOGS: $1 >> $LOGS
}

# check software
check_software() {
    which $1 >> /dev/null
    if [ $? = 0 ]; then
        print_log "$1 had been installed"
    else
        print_log "$1 is not installed, installing now"
        sudo $2 $1 -y
    fi
}

## update && upgrade system
update_system()
{
    print_log "UPDATE SYSTEM..."
    sudo apt update -y
    if [ $? = 0 ] 
        then print_log "UPDATE SYSTEM SUCCESSFULLY"
    else
        print_log "ERROR WHEN UPDATE SYSTEM"
    fi
    sudo apt upgrade
    if [ $? = 0 ] 
        then print_log "UPGRADE SYSTEM SUCCESSFULLY" 
    else
        print_log "ERROR WHEN UPGRADE SYSTEM"
    fi
}


# config vim
config_vim() {
    print_log "do config for vim..."
    # vim had been installed?
    check_software vim 'apt install'
    # clang had been installed?
    check_software clang 'apt install'
    # cmake had been installed?
    check_software cmake 'apt install'
    # for .vimrc
    if [ -f "$HOME/.vimrc" ]; then 
        print_log "mv $HOME/.vimrc to $HOME/.vimrc.bak"
        mv $HOME/.vimrc $HOME/.vimrc.bak
    fi
    # for .vim
    if [  -d "$HOME/.vim" ]; then  
        print_log "mv $HOME/.vim to $HOME/.vim.bak"
        mv $HOME/.vim $HOME/.vim.bak
    fi
    # do config
    cp $relative_location/res/vim/.vimrc $HOME/
    cp $relative_location/res/vim/.ycm_extra_conf.py $HOME/
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
    cp -r $relative_location/res/vim/colors ~/.vim/
    vim +PluginInstall +qall
    print_log 'config youcompleteme'
    $HOME/.vim/bundle/YouCompleteMe/install.sh  --clang-completer --system-libclang
    print_log "done"
}

## config the zsh
config_zsh()
{
    print_log "CONFIG ZSH"
    mv ~/.zshrc ~/.zshrc.bck
    # oh my zsh
    wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | sh
    cp $ZSH ~/.zshrc
    cd $HERE
    print_log "STARTING CHSH TO ZSH"
    chsh -s /bin/zsh
    
    if [ $? = 0 ] 
    then print_log "CHSH SUCCESSFULLY"
    else 
        print_log "ERROR WHEN CHSH"
    fi
}

## config the shadowsocks
## You need to config the /res/shadowsocks/shadowsocks.json first
config_shadowsocks()
{
    print_log "CONFIG SS"
    cp $SS /etc/shadowsocks.json
    sudo sed -i "13a    \# Shadowsocks\nnohup /usr/bin/sslocal -c /etc/shadowsocks.json 1>/dev/null 2>/dev/null &" /etc/rc.local
    print_log "done"
}

## config the numlockx
config_numlockx()
{
    print_log "CONFIG Numlockx"
    sudo sed -i "13a    \# Numlock on\nif [-x /usr/bin/numlockx ]; then\n/usr/bin/numlockx on\nfi" /etc/rc.local
    print_log "done"
}

## config the proxychains
config_proxychains()
{
    print_log "CONFIG Proxychains"
    sudo sed -i '$d' /etc/proxychains.conf
    sudo sed -i '$ a\socks5       127.0.0.1 1081' /etc/proxychains.conf
    print_log "done"
}

## config the pyenv
config_pyenv()
{
    print_log "CONFIG Pyenv"
    git clone https://github.com/pyenv/pyenv.git ~/.pyenv
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshenv
    echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshenv
    echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.zshenv
    source ~/.zshenv
    print_log "done"
}

## config the virtualenv
config_virtualenv()
{
    print_log "CONFIG Virtualenv"
    git clone https://github.com/pyenv/pyenv-virtualenv.git $(pyenv root)/plugins/pyenv-virtualenv
    echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.zshenv
    source ~/.zshenv
    print_log "done"
}

## add ppa
add_ppa()
{
    print_log "ADD PPA..."
    sh $PPA
    cd $HERE
    print_log "ADD PPA DONE"
}


## config fonts
config_font()
{
    print_log "ADD MONACO AND YAHEI FONTS TO UBUNTU"
    sudo cp -r $FONTS /usr/share/fonts/
    cd /usr/share/fonts/Monaco
    sudo chmod 755 *
    sudo mkfontscale
    sudo mkfontdir
    sudo fc-cache -fv
    cd $HERE
    print_log "ADD MONACO AND YAHEI DONE"
}


## install applications
install_apps()
{
    # get application from app files
    applications=$(cat $APPS)

    print_log "INSTALL APPLICATIONS..."
    echo "\n"

    for app in $applications; do
        print_log "STARTING TO INSTALL $app"
        sudo apt install ${app} -y
        status=$?
        if [ $status = 0 ] 
        then
            print_log "SUCCESSFULLY INSTALLED"
            success_installed=`expr $success_installed + 1`
            print_log "[√]${app} WAS INSTALLED OR IT WAS EXIST"
        else
            print_log "ERROR WHEN INSTALL $app"
            false_installed=`expr $false_installed + 1`
            print_log "$app WAS NOT BE INATALLED"
        fi
    done

    # install information
    
    print_log "$success_installed APPLICATIONS WERE INSTALLED SUCCESSFULLY"
    print_log "$false_installed APPLICATIONS WERE NOT BE INSTALLED, PLEASE CHECK"

    # install flux to protect your eyes
    print_log "INSTALL flux"

    cd /tmp

    git clone https://github.com/xflux-gui/xflux-gui.git
    cd xflux-gui
    python download-xflux.py 
    sudo python setup.py install
    python setup.py install --user 
    cd $HERE

    # install youdao dictionary
    print_log "INSTALL youdao"

    sudo git clone https://github.com/longcw/youdao.git /opt/youdao_dict
    cd /opt/youdao_dict/
    sudo python setup.py install
    cd $HERE

    # install cloudmusic
    print_log "INSTALL cloudmusic"
    cd /tmp
    netMusicLink="http://s1.music.126.net/download/pc/netease-cloud-music_1.0.0-2_amd64_ubuntu16.04.deb"
    netMusicName="netMusic.deb"
    sudo wget -O ${netMusicName} -c ${netMusicLink}
    sudo dpkg -i ${netMusicName} 

    # install vbox
    print_log "INSTALL vbox"
    virtualBoxLink="http://download.virtualbox.org/virtualbox/5.2.0/virtualbox-5.2_5.2.0-118431~Ubuntu~xenial_amd64.deb"
    virtualBoxName="virtualBox.deb"
    sudo wget -O ${virtualBoxName} -c ${virtualBoxLink}
    sudo dpkg -i ${virtualBoxName}

    # install sougou input
    print_log "INSTALL sougou input"
    sougouLink="http://cdn2.ime.sogou.com/dl/index/1491565850/sogoupinyin_2.1.0.0086_amd64.deb?st=bBYOyY4OxnTa-_ElgJuKDw&e=1508784697&fn=sogoupinyin_2.1.0.0086_amd64.deb"
    sougouName="sougou.deb"
    sudo wget -O ${sougouName} -c ${sougouLink}
    sudo dpkg -i ${sougouName}
    cd $HERE

    # install chrome && WPS
    # You may uncomment 6 lines if you have the deb packages
    #
    #print_log "INSTALL Chrome"
    #cd $HERE/res/apps/
    #sudo dpkg -i google-chrome-stable*.deb
    #sudo dpkg -i wps-office*.deb
    #sudo dpkg -i winfonts*.deb
    #sudo dpkg -i symbol-fonts*.deb

    # resolve dependence
    sudo apt -f install
    print_log "INSTALL APPLICATIONS DONE"
}


## icons
config_icons()
{
    print_log "ADD ICON: PAPIRUS"

    wget -qO- https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-icon-theme/master/install-papirus-home-gtk.sh | sh

    print_log "ICONS CONFIG DONE"
}


## theme for Ambiance mac like
config_theme()
{
    print_log "ADD Ambiance_Mac THEME"
    print_log "CP Ambiance_Mac theme TO /usr/share/themes"
    sudo cp -r $THEME /usr/share/themes
}

## background
config_background()
{
    print_log "ADD some backgrounds"
    print_log "CP backgrounds TO ~/Pictures/"
    cp $BACKGROUND ~/Pictures/
}

## powerline font
powerline_fonts()
{
    print_log "ADD POWERLINE FONTS"
    
    git clone https://github.com/powerline/fonts.git
    cd fonts
    ./install.sh 
    cd $HERE
    rm -rf fonts
}


## vscode
config_vscode()
{
    print_log "CONDIF VS CODE"
    mkdir -p $HOME/.config/Code/User/
    cp $VS_CODE $HOME/.config/Code/User/ 
}

print_log "START CONFIGURE UBUNTU..."
print_log "input ./setup.sh -Q for help"

while getopts 012345678A option
do
    case "$option" in
        0)
            echo "install application on your ubuntu and do some configrations " 
            update_system
            install_apps
            config_shadowsocks
            config_numlockx
            config_proxychains
            echo "done";;

        1)
            echo "install Monaco && microsoft yahei && windows' fonts on your ubuntu"
            config_font
            echo "done";;
        2)
            echo "config zsh and pyenv&&virtualenv on your ubuntu"
            config_zsh
            config_pyenv
            config_virtualenv
            echo "done";;
        3)
            echo "config vim on your ubuntu"
            config_vim
            echo "done";;
        4) 
            echo "config icons on your ubuntu"
            config_icons
            echo "done";;
        5) 
            echo "install poerline fonts on your ubuntu"
            powerline_fonts
            echo "done";;
        6)
            echo "add ppa for your system"
            add_ppa
            echo "done";;
        7)
            echo "Ambiance_Mac theme and backgrounds"
            config_theme
            config_background
            echo "done";;
        8)
            echo "visual studio code"
            config_vscode
            echo "done";;

        A)
            echo "do all"
            add_ppa
            update_system
            install_apps
            config_shadowsocks
            config_numlockx
            config_proxychains
            config_font
            powerline_fonts
            config_vim
            config_zsh
            config_pyenv
            config_virtualenv
            config_icons
            config_theme
            config_background
            config_vscode
            echo "done";;

        \?)
            echo "------------------------------HELP------------------------------------"
            echo "----------------------------------------------------------------------"
            echo "|-0  install applications                                            |"
            echo "|-1  install monaco && micosoft yahei fonts                          |"
            echo "|-2  config zsh and pyenv&&virtualenv                                                    |"
            echo "|-3  config vim                                                      |"
            echo "|-4  config icons                                                    |"
            echo "|-5  install powerline fonts                                         |"
            echo "|-6  add ppa                                                         |"
            echo "|-7  Ambiance_Mac theme                                              |"
            echo "|-8  visual studio code                                              |"    
            echo "|-A  do all for your system, if your system is new one               |"
            echo "----------------------------------------------------------------------"
            echo "------------------------------NOTE------------------------------------"
            echo "|if you use zsh && vim, you should install powerline fonts at first  |"
            echo "|if you want to install apps, you should add ppa at first            |"
            echo "----------------------------------------------------------------------"
            echo "bye";;
    esac
done
