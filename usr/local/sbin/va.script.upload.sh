#!/bin/bash

# log
logger "$0"

# cartella base
FOLD=/root

# creo la versione corrente
VERS=$(va.txt.timestamp.compressed.sh)

# nome della cartella per Github
GITHUB=/script.github/calabash

# NOTA
# gli script si pubblicano solo su GitHub ( istricesrl/calabash ): il vecchio sito
# calabash.videoarts.eu con gli archivi tar è stato dismesso il 12/11/2026

# copio gli script nella cartella per Github
cp -r --parents /usr/local/bin/va.* $FOLD$GITHUB
cp -r --parents /usr/local/sbin/va.* $FOLD$GITHUB
cp -r --parents /usr/local/share/doc/va.* $FOLD$GITHUB

# aggiorno il numero di versione sul repository
echo $VERS > $FOLD$GITHUB/usr/local/etc/va.script.version

# cambio cartella
cd $FOLD$GITHUB

# pull
git pull

# push
git add .
git commit -am "aggiornamento script del $(date)"
git push

# uscita
exit $?

## NOTA
# git remote remove origin
# git remote -v
# git remote add origin git@github.com:istricesrl/calabash.git
# git push --set-upstream origin master
#