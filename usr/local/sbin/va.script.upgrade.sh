#!/bin/bash

# log
logger "$0"

# protezione: sulla macchina di sviluppo gli script si pubblicano con va.script.upload.sh
if [ -d /root/script.github/calabash/.git ]; then

echo "aggiornamento degli script non consentito sulla macchina di sviluppo"

else

# aggiorno il sistema
apt-get update && apt-get upgrade

# pacchetti necessari
apt-get install wget unzip

# cartella d'archivio per gli script correnti
BAKDIR="/root/script.$(va.txt.timestamp.compressed.sh)/"

# installazione wget
apt-get install -y wget

# creo la cartella d'archivio
mkdir -p $BAKDIR

# elimino i vecchi script
mv /usr/local/bin/va.* $BAKDIR
mv /usr/local/sbin/va.* $BAKDIR
mv /usr/local/share/doc/va.* $BAKDIR

# cambio cartella
cd /root

# scarico l'ultima versione da GitHub
wget https://github.com/istricesrl/calabash/archive/refs/heads/master.zip

# scompatto gli script
unzip -qq ./master.zip

# installo gli script: si copia solo usr/, README e LICENSE non vanno nella radice
# la versione arriva con usr/local/etc/va.script.version
cp -R ./calabash-master/usr/. /usr/

# elimino il file scaricato
rm -rf ./master.zip
rm -rf ./calabash-master

# journal
va.log.journal.sh "aggiornamento degli script"

fi

# uscita
exit $?

# NOTA
# gli script si distribuiscono solo da GitHub ( istricesrl/calabash, ramo master ):
# il vecchio sito calabash.videoarts.eu con gli archivi tar è stato dismesso il 12/11/2026
