#!/bin/bash

# log
logger "$0"

# cartella d'archivio per gli script correnti
BAKDIR="/root/script.$(va.txt.timestamp.compressed.sh)/"

# installazione wget
apt-get install -y wget

# creo la cartella d'archivio
mkdir -p $BAKDIR

# elimino i vecchi script
mv /usr/bin/va.* $BAKDIR
mv /usr/sbin/va.* $BAKDIR
mv /usr/share/doc/va.* $BAKDIR

# cambio cartella
cd /root

# scarico l'ultima versione
# wget http://calabash.videoarts.it/va.current.tar -O va.current.tar
wget https://github.com/istricesrl/calabash/archive/refs/heads/master.zip

# scompatto gli script
# tar -xf va.current.tar -C /
unzip -qq ./calabash-master.zip

# installo gli script
cp -R ./calabash-master/* /

# elimino il file scaricato
# rm -f va.current.tar
rm -rf ./calabash-master*

# annoto la versione corrente
# echo $(va.curl.get.value.sh http://calabash.videoarts.it/va.current.version) > /etc/va.script.version

# journal
va.log.journal.sh "aggiornamento degli script"

# uscita
exit $?

# NOTA
# -x estrae dall'archivio
# -f specifica il file
# -C specifica la cartella dove posizionare i file estratti (tenendo conto del path presente nell'archivio)
