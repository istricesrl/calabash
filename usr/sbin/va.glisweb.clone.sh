#!/bin/bash

# log
logger "$0 $1"

# controllo i parametri
if [[ -n $1 ]]; then

    # creo la document root
    sudo mkdir -p $1

    # clono il repository
    git clone https://github.com/istricesrl/glisweb.git

    # sposto il repository
    sudo cp -rf ./glisweb/{.[!.],}* $1/

    # elimino la cartella di installazione
    sudo rm -rf ./glisweb

    # TODO chiedere la branch

    # aggiorno composer
    cd $1/ && apt-get install composer && composer update

    # permessi
    # $1/_src/_sh/_gw.permissions.reset.sh

    # richiesta
    echo -n "vuoi installare l'ambiente LAMP (s/n)? "
    read YN

    # configurazione
    if [ "$YN" = "s" ]; then
        # TODO verificare che venga giù con i permessi di esecuzione
        $1/_src/_sh/_gw.environment.setup.sh
    fi

    # richiesta
    echo -n "vuoi installare il database del sito (s/n)? "
    read YN

    # configurazione
    if [ "$YN" = "s" ]; then
        $1/_src/_sh/_gw.mysql.install.sh
    fi

    # richiesta
    echo -n "vuoi configurare il framework (s/n)? "
    read YN

    # configurazione
    if [ "$YN" = "s" ]; then
        $1/_src/_sh/_gw.config.sh base
    fi

else

    # help
    echo "$0 <cartella>"

fi

# valore di uscita
exit $?
