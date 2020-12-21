#!/bin/bash

set -e

export RSYNC_OPTIONS="-ahR --info=progress2 --no-inc-recursive"
export HOME_DIR="/home/lzkill"
export BACKUP_DIR="/media/lzkill/m3/vostro"

help()
{
    echo ""
    echo "Usage: $0 -b | -c | -d | -i | -r"
    echo -e "\t-b Backup"
    echo -e "\t-c Configure"
    echo -e "\t-d Download"
    echo -e "\t-i Install"
    echo -e "\t-r Restore"
    exit 1
}

backup() {
    BACKUP_TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    LATEST_BACKUP_DIR="$BACKUP_DIR/$BACKUP_TIMESTAMP"
    mkdir -p "$LATEST_BACKUP_DIR"
    ln -sfn "$LATEST_BACKUP_DIR" "$BACKUP_DIR/latest"
    
    rsync $RSYNC_OPTIONS \
    --exclude "$HOME_DIR/.var/app/*/cache" \
    "$HOME_DIR/.var/app" \
    "$HOME_DIR/.vimrc" \
    "$HOME_DIR/.gitconfig" \
    "$HOME_DIR/.gitignore" \
    "$HOME_DIR/.bash_aliases" \
    "$HOME_DIR/.bashrc" \
    "$HOME_DIR/.dropbox" \
    "$HOME_DIR/.docker-remote-cli" \
    "$HOME_DIR/.ssh" \
    "$HOME_DIR/.gnupg" \
    "$HOME_DIR/.eclipse" \
    "$HOME_DIR/.visualvm/2.0.5/repository" \
    "$HOME_DIR/.config/VirtualBox" \
    "$HOME_DIR/.config/google-chrome" \
    "$HOME_DIR/.config/FortiClient" \
    "$HOME_DIR/rdp" \
    "$HOME_DIR/Desktop" \
    "$HOME_DIR/Documents" \
    "$HOME_DIR/Downloads" \
    "$HOME_DIR/Dropbox" \
    "$HOME_DIR/Pictures" \
    "$HOME_DIR/Projects" \
    "$HOME_DIR/Software" \
    "$HOME_DIR/VirtualBox VMs" \
    /etc/default/locale \
    /etc/hostname \
    /etc/hosts \
    /etc/docker/daemon.json \
    /usr/local/bin/file.io \
    /usr/local/bin/git-summary \
    "$LATEST_BACKUP_DIR/"
    
    sync
}

global-configure() {
    hostname vostro
    usermod -aG docker lzkill
    locale-gen pt_BR.UTF-8
}

local-configure() {
    gsettings set org.gnome.settings-daemon.plugins.power button-power 'suspend'
}

download() {
    # jxxplorer
    wget -P "$HOME_DIR/Downloads" https://bit.ly/34xBDSl
}

global-install() {
    apt install -y \
    vim htop google-chrome-stable git git-flow curl httpie gawk xsane \
    nautilus-dropbox virtualbox synaptic gnome-tweak-tool nautilus-admin \
    git-lfs
    
    # Forticlient
    wget -O - https://repo.fortinet.com/repo/6.4/ubuntu/DEB-GPG-KEY | apt-key add -
    echo "deb [arch=amd64] https://repo.fortinet.com/repo/6.4/ubuntu/ /bionic multiverse" > \
    /etc/apt/sources.list.d/forticlient.list
    apt update
    apt install -y forticlient
    
    # Docker
    apt install -y \
    apt-transport-https ca-certificates gnupg-agent software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    apt-key fingerprint 0EBFCD88
    add-apt-repository -y \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io
    
    apt autoremove -y
    apt autoclean -y
}

local-install() {
    flatpak install flathub -y \
    com.nextcloud.desktopclient.nextcloud \
    com.github.debauchee.barrier \
    com.spotify.Client \
    org.inkscape.Inkscape \
    org.gimp.GIMP \
    com.microsoft.Teams \
    us.zoom.Zoom \
    com.obsproject.Studio \
    org.flameshot.Flameshot \
    nl.hjdskes.gcolor3 \
    edu.mit.Scratch \
    org.remmina.Remmina \
    com.github.tchx84.Flatseal \
    com.skype.Client \
    org.gnome.meld \
    org.eclipse.Java \
    org.apache.netbeans \
    io.dbeaver.DBeaverCommunity \
    com.visualstudio.code \
    com.getpostman.Postman \
    com.axosoft.GitKraken \
    net.poedit.Poedit
    
    # nvm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install lts/*
    
    # SDKManager
    curl -s "https://get.sdkman.io" | bash
    export SDKMAN_DIR="/home/lzkill/.sdkman"
    [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && \. "$HOME/.sdkman/bin/sdkman-init.sh"
    sdk install java 11.0.9.j9-adpt
    mkdir -p "$HOME/Software/{jdk1.7.0_80,jdk1.8.0_271}"
    sdk install java 8.0.271-oracle $HOME/Software/jdk1.8.0_271
    sdk install java 7.0.80-oracle $HOME/Software/jdk1.7.0_80
}

restore() {
    LATEST_BACKUP_DIR="$BACKUP_DIR/latest"
    rsync $RSYNC_OPTIONS "$LATEST_BACKUP_DIR/*" /
    sync
}

if [ $# -eq 0 ]
then
    echo "No option given";
    help
fi

# See https://unix.stackexchange.com/a/337820
# See https://unix.stackexchange.com/a/269080
while getopts "bcdir" opt
do
    case "$opt" in
        b ) sudo -E bash -c "$(declare -f backup); backup" ;;
        c ) sudo -E bash -c "$(declare -f global-configure); global-configure" && local-configure ;;
        d ) download ;;
        i ) sudo -E bash -c "$(declare -f global-install); global-install" && local-install ;;
        r ) sudo -E bash -c "$(declare -f restore); restore" ;;
        ? ) help ;;
    esac
done

