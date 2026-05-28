#!/bin/bash

install_package() {
    apt install -y $1
    dpkg-reconfigure $1
}

PACCHETTI="aptitude mc links less ncftp whois bzip2 whiptail pwgen at rsync locales tzdata unattended-upgrades"
PACCHETTI="$PACCHETTI gnutls-bin libsasl2-modules bash-completion libconfig-inifiles-perl debian-keyring debian-archive-keyring lsb-release"
PACCHETTI="$PACCHETTI iotop htop iftop psmisc ncdu lsof speedtest-cli"
PACCHETTI="$PACCHETTI ethtool jq wget curl ntp net-tools dsh dnsutils nmap"
PACCHETTI="$PACCHETTI texlive-latex-base doxygen-latex texlive-lang-italian a2ps"
PACCHETTI="$PACCHETTI ffmpeg mediainfo"

apt update && apt upgrade

for p in $PACCHETTI; do

    read -p "vuoi installare $p (s/n)? " yn
    case $yn in
        [Nn]* ) ;;
        * ) install_package $p; ;;
    esac

done

