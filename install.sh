#!/bin/bash

# installazione di calabash da GitHub
#
#   wget https://raw.githubusercontent.com/istricesrl/calabash/master/install.sh && chmod +x ./install.sh && ./install.sh
#
# da lanciare come root da una cartella di lavoro, non dalla radice

# pacchetti necessari
apt-get update && apt-get upgrade
apt-get install wget unzip

# scarico l'ultima versione
wget https://github.com/istricesrl/calabash/archive/refs/heads/master.zip
unzip -qq ./master.zip

# installo gli script: si copia solo usr/, README e LICENSE non vanno nella radice
cp -R ./calabash-master/usr/. /usr/

# pulizia
rm -rf ./master.zip
rm -rf ./calabash-master
rm -f ./install.sh
