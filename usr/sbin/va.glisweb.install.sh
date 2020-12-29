#!/bin/bash

# log
logger "$0 $1"

# controllo i parametri
if [[ -n $1 ]]; then

    if [[ -z $2 ]]; then
        BRANCH=master
    else
        BRANCH=$2
    fi

    # scarico Glisweb
    wget https://github.com/istricesrl/glisweb/archive/$BRANCH.zip

    # scompatto Glisweb
    unzip ./$BRANCH.zip

    # elimino il vecchio framework
    rm -rf ./$1/_*

    # installo la nuova versione
    rsync -a ./glisweb-$BRANCH/* ./$1

    # elimino la vecchia cartella
    rm -rf ./glisweb-$BRANCH
    rm -rf ./$BRANCH.zip

    # installo il .gitignore se è presente un repository .git
    if [ -f ./$1/_usr/_deploy/_git/.gitignore -a -d ./$1/.git ]; then
        cp ./$1/_usr/_deploy/_git/.gitignore ./$1/.gitignore
    fi

    # aggiorno composer
    cd $1/
    composer update

else

    # help
    echo "$0 <cartella> [branch]"

fi

# valore di uscita
exit $?
