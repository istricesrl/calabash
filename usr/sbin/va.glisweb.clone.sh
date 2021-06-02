#!/bin/bash

# log
logger "$0 $1"

# controllo i parametri
if [[ -n $1 ]]; then

    # creo la document root
    mkdir -p $1

    # clono il repository
    git clone git@github.com:istricesrl/glisweb.git

    # sposto il repository
    cp -rf ./glisweb/{.[!.],}* $1/

    # elimino la cartella di installazione
    rm -rf ./glisweb

    # aggiorno composer
    cd $1/ && composer update

    # permessi
    $1/_src/_sh/_gw.permissions.reset.sh

    # richiesta
    echo -n "vuoi installare l'ambiente LAMP (s/n)? "
    read YN

    # configurazione
    if [ "$YN" = "s" ]; then
        $1/_src/_sh/_gw.environment.setup.sh
    fi

    # richiesta
    echo -n "vuoi installare il database del sito e configurare il framework ora (s/n)? "
    read YN

    # configurazione
    if [ "$YN" = "s" ]; then
        $1/_src/_sh/_gw.mysql.install.sh
        $1/_src/_sh/_gw.config.sh base
    fi

else

    # help
    echo "$0 <cartella> [branch]"

fi

# valore di uscita
exit $?
