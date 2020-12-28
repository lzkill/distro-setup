#!/bin/bash

set -e

export home_dir="/home/lzkill"
export backup_dir="/media/lzkill/m3/vostro"
export rsync_options="-ahR --info=progress2 --no-inc-recursive"

help() {
  echo ""
  echo "Usage: $0 -b | -c | -i | -r"
  echo -e "\t-b Backup"
  echo -e "\t-c Configure"
  echo -e "\t-i Install"
  echo -e "\t-r Restore"
  exit 1
}

backup() {
  local backup_timestamp
  backup_timestamp=$(date +"%Y%m%d_%H%M%S")

  local latest_backup_dir
  latest_backup_dir="$backup_dir/$backup_timestamp"

  mkdir -p "$latest_backup_dir"
  ln -sfn "$latest_backup_dir" "$backup_dir/latest"

  rsync $rsync_options \
    --exclude "$home_dir/.var/app/*/cache" \
    "$home_dir/.var/app" \
    "$home_dir/.vimrc" \
    "$home_dir/.gitconfig" \
    "$home_dir/.gitignore" \
    "$home_dir/.bash_aliases" \
    "$home_dir/.bashrc" \
    "$home_dir/.dropbox" \
    "$home_dir/.docker-remote-cli" \
    "$home_dir/.ssh" \
    "$home_dir/.gnupg" \
    "$home_dir/.eclipse" \
    "$home_dir/.vscode" \
    "$home_dir/.visualvm/2.0.5/repository" \
    "$home_dir/.config/Code" \
    "$home_dir/.config/VirtualBox" \
    "$home_dir/.config/google-chrome" \
    "$home_dir/.config/FortiClient" \
    "$home_dir/.local/share/gnome-shell/extensions" \
    "$home_dir/.openfortigui" \
    "$home_dir/rdp" \
    "$home_dir/snap" \
    "$home_dir/Desktop" \
    "$home_dir/Documents" \
    "$home_dir/Downloads" \
    "$home_dir/Dropbox" \
    "$home_dir/Pictures" \
    "$home_dir/Projects" \
    "$home_dir/Software" \
    "$home_dir/VirtualBox VMs" \
    /etc/default/locale \
    /etc/hostname \
    /etc/hosts \
    /etc/systemd/resolved.conf \
    /etc/docker/daemon.json \
    /usr/local/bin/file.io \
    /usr/local/bin/git-summary \
    "$latest_backup_dir/"

  sync
}

configure_system() {
  hostname vostro
  locale-gen pt_BR.UTF-8
}

configure_gnome() {
  gsettings set org.gnome.settings-daemon.plugins.power button-power 'suspend'
  gsettings set org.gnome.desktop.wm.preferences button-layout ":minimize,maximize,close"
}

install_system_wide() {
  install_apt_packages
  install_forticlient
  install_docker
  install_warsaw
}

install_apt_packages() {
  apt install -y \
    vim htop google-chrome-stable git git-flow curl httpie gawk xsane \
    nautilus-dropbox virtualbox synaptic gnome-tweak-tool nautilus-admin \
    git-lfs ubuntu-restricted-extras gir1.2-gst-plugins-base-1.0 \
    code snapd openfortivpn

  apt autoremove -y
  apt autoclean -y
}

install_forticlient() {
  wget https://apt.iteas.at/iteas/pool/main/o/openfortigui/openfortigui_0.9.3-1_amd64_focal.deb
  dpkg -i openfortigui_0.9.3-1_amd64_focal.deb
  rm openfortigui_0.9.3-1_amd64_focal.deb
}

install_docker() {
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
  usermod -aG docker lzkill
}

install_warsaw() {
  wget https://cloud.gastecnologia.com.br/cef/warsaw/install/GBPCEFwr64.deb
  dpkg -i GBPCEFwr64.deb
  rm GBPCEFwr64.deb
}

install_user_wide() {
  install_flatpaks
  install_snaps
  install_nvm
  install_sdkman

  install_gnome_extensions
  killall -SIGQUIT gnome-shell
}

install_flatpaks() {
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
    com.getpostman.Postman \
    com.axosoft.GitKraken \
    net.poedit.Poedit \
    org.gnome.Evolution \
    flathub com.meetfranz.Franz
}

install_snaps() {
  snap install snap-store
}

install_nvm() {
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
  export nvm_dir="$HOME/.nvm"
  [ -s "$nvm_dir/nvm.sh" ] && \. "$nvm_dir/nvm.sh"
  nvm install lts/*
}

install_sdkman() {
  curl -s "https://get.sdkman.io" | bash
  export sdkman_dir="$HOME/.sdkman"
  [[ -s "$sdkman_dir/bin/sdkman-init.sh" ]] && \. "$sdkman_dir/bin/sdkman-init.sh"
  sdk install java 11.0.9.j9-adpt
  sdk install java 8.0.271-oracle "$HOME/Software/jdk1.8.0_271"
  sdk install java 7.0.80-oracle "$HOME/Software/jdk1.7.0_80"
}

install_gnome_extension() {
  local tmp_dir
  tmp_dir=$(mktemp -d)

  wget "https://extensions.gnome.org/extension-data/$1"
  unzip -q "$1" -d "$tmp_dir/"

  local uuid
  uuid=$(grep uuid "$tmp_dir/metadata.json" | cut -d \" -f4)
  local extension_dir
  extension_dir="$HOME/.local/share/gnome-shell/extensions/$uuid"

  mkdir -p "$extension_dir"
  rsync -auvP "$tmp_dir/" "$extension_dir/"

  rm -rf "$1" "$tmp_dir"
}

install_gnome_extensions() {
  install_gnome_extension "dash-to-dockmicxgx.gmail.com.v69.shell-extension.zip"
  install_gnome_extension "radiohslbck.gmail.com.v14.shell-extension.zip"
  install_gnome_extension "sound-output-device-chooserkgshank.net.v32.shell-extension.zip"
  install_gnome_extension "update-extensions@franglais125.gmail.com.v9.shell-extension.zip"
}

restore() {
  rsync $rsync_options "$backup_dir/latest/" /
  sync
}

run_with_sudo() {
  sudo -E bash -c "$(declare -f); $1"
}

if [ $# -eq 0 ]; then
  echo "No option given"
  help
fi

# See https://unix.stackexchange.com/a/337820
# See https://unix.stackexchange.com/a/269080
while getopts "bcir" opt; do
  case "$opt" in
    b)
      run_with_sudo "backup"
      ;;
    c)
      run_with_sudo "configure_system"
      configure_gnome
      ;;
    i)
      run_with_sudo "install_system_wide"
      install_user_wide
      ;;
    r)
      run_with_sudo "restore"
      ;;
    ?)
      help
      ;;
  esac
done
