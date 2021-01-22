#!/bin/bash

set -e

export home_dir="/home/$USER"
export backup_dir="/media/$USER/m3/distro-setup"

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
  rm "$backup_dir/latest"
  ln -s -r "$latest_backup_dir" "$backup_dir/latest"

  rsync -ahR --info=progress2 --no-inc-recursive \
    --exclude "$home_dir/.var/app/*/cache" \
    "$home_dir/.bash_aliases" \
    "$home_dir/.bash_history" \
    "$home_dir/.bashrc" \
    "$home_dir/.config/Code" \
    "$home_dir/.config/FortiClient" \
    "$home_dir/.config/google-chrome" \
    "$home_dir/.config/Nextcloud" \
    "$home_dir/.config/VirtualBox" \
    "$home_dir/.davmail.properties" \
    "$home_dir/.docker-remote-cli" \
    "$home_dir/.dropbox" \
    "$home_dir/.eclipse" \
    "$home_dir/.gitconfig" \
    "$home_dir/.gitignore" \
    "$home_dir/.gnupg" \
    "$home_dir/.gse-radio" \
    "$home_dir/.local/share/DBeaverData" \
    "$home_dir/.local/share/gnome-shell/extensions" \
    "$home_dir/.local/share/Trash" \
    "$home_dir/.nvm" \
    "$home_dir/.mysql/workbench" \
    "$home_dir/.openfortigui" \
    "$home_dir/.pam_environment" \
    "$home_dir/.profile" \
    "$home_dir/.sdkman" \
    "$home_dir/.ssh" \
    "$home_dir/.thunderbird" \
    "$home_dir/.var/app" \
    "$home_dir/.vimrc" \
    "$home_dir/.visualvm/2.0.5/repository" \
    "$home_dir/.vscode" \
    "$home_dir/.workplaces" \
    "$home_dir/Desktop" \
    "$home_dir/Documents" \
    "$home_dir/Downloads" \
    "$home_dir/Dropbox" \
    "$home_dir/Nextcloud" \
    "$home_dir/Pictures" \
    "$home_dir/Projects" \
    "$home_dir/scripts" \
    "$home_dir/snap" \
    "$home_dir/Software" \
    "$home_dir/VirtualBox VMs" \
    /etc/default/locale \
    /etc/docker/daemon.json \
    /etc/hostname \
    /etc/hosts \
    /etc/systemd/network/100-ppp0.network \
    /usr/local/bin/file.io \
    /usr/local/bin/git-summary \
    /usr/local/bin/gpush \
    /usr/local/bin/gtag \
    /usr/share/mysql-workbench/data/code_editor.xml \
    "$latest_backup_dir/"

  sync
}

configure_system() {
  hostname rbs-adds64819
  locale-gen pt_BR.UTF-8
  system76-power graphics hybrid
  systemctl enable fstrim.timer
  systemctl enable systemd-networkd
  timedatectl set-local-rtc 1 --adjust-system-clock
  usermod -a -G vboxusers $USER
  usermod -a -G disk $USER

  mkdir -p /mnt/nfs/{dwh2,dwp2,hom-nfs}
  cat nfs.conf >>/etc/fstab
}

configure_gnome() {
  gsettings set org.gnome.settings-daemon.plugins.power button-power 'suspend'
  gsettings set org.gnome.desktop.wm.preferences button-layout ":minimize,maximize,close"
}

configure_user_wide() {
  configure_gnome
  git config pull.rebase false
}

install_system_wide() {
  install_apt_packages
  install_offline_packages
  install_snaps
  install_forticlient
  install_docker
  install_warsaw
}

install_apt_packages() {
  echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections

  apt install -y \
    ubuntu-restricted-extras vim htop pv nfs-common xsane gparted snapd \
    google-chrome-stable openfortivpn synaptic gnome-tweak-tool nautilus-admin \
    virtualbox virtualbox-ext-pack virtualbox-guest-additions-iso \
    nautilus-dropbox nextcloud-desktop nautilus-nextcloud \
    gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly gir1.2-gst-plugins-base-1.0 libzip5 \
    git git-flow git-lfs curl httpie gawk code uchardet recode grub-customizer nmap python3-pip \
    libpython2.7 libpython2.7-minimal libpython2.7-stdlib \
    mysql-client git-svn

  apt autoremove -y
  apt autoclean -y
}

install_offline_packages() {
  local latest_backup_dir
  latest_backup_dir=$(readlink -f $backup_dir/latest$home_dir/Downloads/Installers)
  pushd . && cd "$latest_backup_dir"
  dpkg -i ./*.deb
  popd
}

install_snaps() {
  snap install snap-store
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
  apt install -y docker-ce docker-ce-cli containerd.io docker-compose
  usermod -aG docker $USER
}

install_warsaw() {
  wget https://cloud.gastecnologia.com.br/cef/warsaw/install/GBPCEFwr64.deb
  dpkg -i GBPCEFwr64.deb
  rm GBPCEFwr64.deb
}

install_user_wide() {
  install_flatpaks
  pip install extract-msg
}

install_flatpaks() {
  flatpak config --unset languages
  flatpak config --set extra-languages "en;pt_BR"

  flatpak install -y flathub \
    com.github.debauchee.barrier \
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
    net.poedit.Poedit \
    com.getferdi.Ferdi \
    com.spotify.Client \
    com.syntevo.SmartGit \
    com.github.calo001.fondo \
    org.kde.kcachegrind \
    org.mozilla.Thunderbird \
    org.davmail.DavMail
}

restore() {
  local latest_backup_dir
  latest_backup_dir=$(readlink -f $backup_dir/latest)
  rsync -ah --info=progress2 --no-inc-recursive "$latest_backup_dir/" /
  sync
}

run_with_sudo() {
  sudo -E bash -c "$(declare -f); $1"
}

if [ $# -eq 0 ]; then
  echo "No option given"
  help
fi

while getopts "bcir" opt; do
  case "$opt" in
    b)
      run_with_sudo "backup"
      ;;
    c)
      run_with_sudo "configure_system"
      configure_user_wide
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
