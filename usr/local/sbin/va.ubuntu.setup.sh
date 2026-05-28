#!/bin/bash

# aggiornamenti
sudo apt --fix-broken install -y
sudo apt-get update -y && sudo apt-get upgrade -y

# Google Chrome
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install -y ./google-chrome-stable_current_amd64.deb
rm -f ./google-chrome-stable_current_amd64.deb

# Slack
# sudo apt-get install -y gconf2 gconf-service libappindicator1
# wget https://downloads.slack-edge.com/linux_releases/slack-desktop-4.10.3-amd64.deb
# sudo dpkg -i slack-desktop-*.deb
# rm -f slack-desktop-*.deb
sudo snap install slack --classic

# Postman
sudo snap install postman

# MS Visual Studio Code
# wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
# sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
# sudo sh -c 'echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
# sudo apt-get install apt-transport-https
# sudo apt-get update
# sudo apt-get install code
# rm -f packages.microsoft.gpg
sudo snap install code --classic

# Dropbox
# sudo sh -c 'echo "deb [arch=i386,amd64] http://linux.dropbox.com/ubuntu disco main" > /etc/apt/sources.list.d/dropbox.list'
# sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1C61A2656FB57B7E4DE0F4C1FC918B335044912E
# sudo apt update
# sudo apt install python3-gpg dropbox
sudo apt-get install dropbox

# GIMP
sudo apt-get install -y gimp

# Inkscape
sudo apt-get install -y inkscape

# Audacity
sudo apt-get install -y audacity

# Kdenlive
sudo apt-get install -y kdenlive

# VLC media player
sudo apt-get install -y vlc

# Meld
sudo apt-get install -y meld

# OBS Studio
sudo apt-get install -y obs-studio

# SimpleScreenRecorder
sudo apt-get install -y simplescreenrecorder

# TeamViewer
wget https://download.teamviewer.com/download/linux/teamviewer_amd64.deb
dpkg -i ./teamviewer_amd64.deb
rm -f ./teamviewer_amd64.deb

# Filezilla
sudo apt-get install -y filezilla

# Font Manager
sudo sudo apt-get install -y font-manager

# pacchetti di estensione
sudo apt-get install -y ubuntu-restricted-extras

# altri pacchetti utili
sudo apt-get install -y ssh
sudo apt-get install -y openssh-server
sudo apt-get install -y pwgen
sudo apt-get install -y htop
sudo apt-get install -y wget
sudo apt-get install -y curl
sudo apt-get install -y mc
sudo apt-get install -y git

# Zoom
# sudo apt-get install -y libegl1-mesa libgl1-mesa-glx libxcb-xtest0
# wget https://zoom.us/client/latest/zoom_amd64.deb
# sudo dpkg -i ./zoom_amd64.deb
# sudo rm -f ./zoom_amd64.deb
sudo snap install zoom-client

# Skype
sudo snap install skype --classic

# Spotify
sudo snap install spotify

# aggiornamenti
sudo apt-get update -y && sudo apt-get upgrade -y

# pulizia
sudo apt-get autoremove -y
