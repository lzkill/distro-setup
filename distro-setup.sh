#!/bin/bash

set -e

export RSYNC_OPTIONS="-ahvRP"
export HOME_DIR="/home/lzkill"
export BACKUP_DIR="/media/lzkill/m3/vostro"

help()
{
   echo ""
   echo "Usage: $0 [-b | -c | -d | -i | -r]"
   echo -e "\t-b Backup"
   echo -e "\t-c Configure"
   echo -e "\t-d Download"
   echo -e "\t-i Install"
   echo -e "\t-r Restore"
   exit 1
}

backup() {
    mkdir -p "$BACKUP_DIR"

    rsync "$RSYNC_OPTIONS" "$HOME_DIR/.vimrc" "$BACKUP_DIR/"
    rsync "$RSYNC_OPTIONS" "$HOME_DIR/.gitconfig" "$BACKUP_DIR/"
    rsync "$RSYNC_OPTIONS" "$HOME_DIR/.gitignore" "$BACKUP_DIR/"
    rsync "$RSYNC_OPTIONS" "$HOME_DIR/.bash_aliases" "$BACKUP_DIR/"
    rsync "$RSYNC_OPTIONS" "$HOME_DIR/.bashrc" "$BACKUP_DIR/"
    rsync "$RSYNC_OPTIONS" "$HOME_DIR/.docker-remote-cli" "$BACKUP_DIR/"
    rsync "$RSYNC_OPTIONS" "$HOME_DIR/.ssh" "$BACKUP_DIR/"
    rsync "$RSYNC_OPTIONS" "$HOME_DIR/.visualvm/2.0.5/repository" "$BACKUP_DIR/"
    rsync "$RSYNC_OPTIONS" "$HOME_DIR/rdp" "$BACKUP_DIR/"
    rsync "$RSYNC_OPTIONS" "$HOME_DIR/Documents" "$BACKUP_DIR/"
    rsync "$RSYNC_OPTIONS" "$HOME_DIR/Projects" "$BACKUP_DIR/"
    rsync "$RSYNC_OPTIONS" "$HOME_DIR/Software" "$BACKUP_DIR/"

    rsync "$RSYNC_OPTIONS" /etc/docker/daemon.json "$BACKUP_DIR/"
    rsync "$RSYNC_OPTIONS" /usr/local/bin/file.io "$BACKUP_DIR/"
    rsync "$RSYNC_OPTIONS" /usr/local/bin/git-summary "$BACKUP_DIR/"

    sync
}

configure() {
    usermod -aG docker lzkill
}

download() {
    wget -P "$HOME_DIR/Downloads" https://megalink.dl.sourceforge.net/project/jxplorer/jxplorer/version%203.3.1.2/jxplorer-3.3.1.2-linux-installer.run
}

global-install() {
    apt install -y \
    vim htop google-chrome-stable \
    git git-flow curl httpie gawk xsane nautilus-dropbox \
    virtualbox synaptic

    # Forticlient
    wget -O - https://repo.fortinet.com/repo/6.4/ubuntu/DEB-GPG-KEY | apt-key add -
    echo "deb [arch=amd64] https://repo.fortinet.com/repo/6.4/ubuntu/ /bionic multiverse" > /etc/apt/sources.list.d/forticlient.list
    apt-get update
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
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
}

local-install() {
    flatpak install -y com.github.debauchee.barrier
    flatpak install -y com.spotify.Client
    flatpak install -y org.inkscape.Inkscape
    flatpak install -y org.gimp.GIMP
    flatpak install -y com.microsoft.Teams
    flatpak install -y us.zoom.Zoom
    flatpak install -y com.obsproject.Studio
    flatpak install -y org.flameshot.Flameshot
    flatpak install -y nl.hjdskes.gcolor3
    flatpak install -y edu.mit.Scratch
    flatpak install -y org.remmina.Remmina

    flatpak install -y org.gnome.meld
    flatpak install -y org.eclipse.Java
    flatpak install -y org.apache.netbeans
    flatpak install -y io.dbeaver.DBeaverCommunity
    flatpak install -y com.visualstudio.code
    flatpak install -y com.getpostman.Postman
    flatpak install -y com.axosoft.GitKraken
    flatpak install -y net.poedit.Poedit

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
    rsync "$RSYNC_OPTIONS" "$BACKUP_DIR/.vimrc" "$HOME_DIR/"
    rsync "$RSYNC_OPTIONS" "$BACKUP_DIR/.gitconfig" "$HOME_DIR/"
    rsync "$RSYNC_OPTIONS" "$BACKUP_DIR/.gitignore" "$HOME_DIR/"
    rsync "$RSYNC_OPTIONS" "$BACKUP_DIR/.bash_aliases" "$HOME_DIR/"
    rsync "$RSYNC_OPTIONS" "$BACKUP_DIR/.bashrc" "$HOME_DIR/"
    rsync "$RSYNC_OPTIONS" "$BACKUP_DIR/.docker-remote-cli" "$HOME_DIR/"
    rsync "$RSYNC_OPTIONS" "$BACKUP_DIR/.ssh" "$HOME_DIR/"
    rsync "$RSYNC_OPTIONS" "$BACKUP_DIR/.visualvm/2.0.5/repository" "$HOME_DIR/"
    rsync "$RSYNC_OPTIONS" "$BACKUP_DIR/rdp" "$HOME_DIR/"
    rsync "$RSYNC_OPTIONS" "$BACKUP_DIR/Documents" "$HOME_DIR/"
    rsync "$RSYNC_OPTIONS" "$BACKUP_DIR/Projects" "$HOME_DIR/"
    rsync "$RSYNC_OPTIONS" "$BACKUP_DIR/Software" "$HOME_DIR/"

    rsync "$RSYNC_OPTIONS" "$BACKUP_DIR/etc/docker/daemon.json" /
    rsync "$RSYNC_OPTIONS" "$BACKUP_DIR/usr/local/bin/{file.io,git-summary}" /
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
      c ) sudo -E bash -c "$(declare -f configure); configure" ;;
      d ) download ;;
      i ) sudo -E bash -c "$(declare -f global-install); global-install" && local-install ;;
      r ) sudo -E bash -c "$(declare -f restore); restore" ;;
      ? ) help ;;
   esac
done

