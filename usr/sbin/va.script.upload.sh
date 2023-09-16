#!/bin/bash

# log
logger "$0"

# percorso del file di archivio
FOLD=/root

# creo la versione corrente
VERS=$(va.txt.timestamp.compressed.sh)

# nome del file di archivio
ARCH="va.$VERS.tar"

# nome della cartella per Github
GITHUB=/script.github

# cartella del sito
DOCROOT=/var/www/calabash.videoarts.eu/dev

# elimino gli eventuali archivi già esistenti
rm -f $FOLD/va.*.tar

# creo l'archivio
tar -cf $FOLD/$ARCH /usr/bin/va.* > /dev/null 2>&1
tar -rf $FOLD/$ARCH /usr/sbin/va.* > /dev/null 2>&1
tar -rf $FOLD/$ARCH /usr/share/doc/va.* > /dev/null 2>&1

# carico l'archivio sul server remoto
# scp $FOLD/$ARCH root@calabash.videoarts.it:/var/www/calabash.videoarts.it/
cp $FOLD/$ARCH $DOCROOT/

# aggiorno il numero di versione sul server remoto
# ssh root@calabash.videoarts.it "echo $VERS > $DOCROOT/va.current.version"
echo $VERS > $DOCROOT/va.current.version

# elimino il vecchio collegamento current.tar sul server remoto
# ssh root@calabash.videoarts.it "rm -f $DOCROOT/va.current.tar"
rm -f $DOCROOT/va.current.tar

# creo il nuovo collegamento current.tar sul server remoto
# ssh root@calabash.videoarts.it "ln -s $DOCROOT/$ARCH $DOCROOT/va.current.tar"
ln -s $DOCROOT/$ARCH $DOCROOT/va.current.tar

# copio gli script nella cartella per Github
cp -r --parents /usr/bin/va.* $FOLD$GITHUB
cp -r --parents /usr/sbin/va.* $FOLD$GITHUB
cp -r --parents /usr/share/doc/va.* $FOLD$GITHUB

# aggiorno il numero di versione sul repository
echo $VERS > $FOLD$GITHUB/etc/va.script.version

# cambio cartella
cd $FOLD$GITHUB

# pull
git pull

# push
git add .
git commit -am "aggiornamento script del $(date)"
git push

# elimino l'archivio
# rm -f $FOLD/$ARCH

# NOTA
# -c crea l'archivio
# -r concatena all'archivio
# -f specifica il file

# NOTA
# per installare gli script scompattare semplicemente l'archivio
# nella cartella radice del server

# uscita
exit $?
