#!/bin/bash

# log
logger "$0 $1 $2"

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

    # cambio cartella
    cd $1/

    # chiedo la branch
    if [ -z "$2" ]; then

        # chiedo
        echo -n "quale branch vuoi usare per il setup (vuoto per master)? "
        read BRANCH

        # configurazione
        if [ -n "$BRANCH" ]; then
            sudo git checkout $BRANCH
        fi

    fi

#    # richiesta
#    echo -n "vuoi installare l'ambiente LAMP (s/n)? "
#    read YN

#    # configurazione
#    if [ "$YN" = "s" ]; then
#        $1/_src/_sh/_gw.environment.setup.sh
#    fi

#    # richiesta
#    echo -n "vuoi installare il database del sito (s/n)? "
#    read YN

#    # configurazione
#    if [ "$YN" = "s" ]; then
#        $1/_src/_sh/_gw.mysql.install.sh
#    fi

    # richiesta
    echo -n "vuoi configurare il framework (s/n)? "
    read YN

    # configurazione
    if [ "$YN" = "s" ]; then
        $1/_src/_sh/_gw.config.sh base
    fi

    # richiesta
    echo -n "utente a cui aggiungere www-data come gruppo di login (vuoto per saltare)? "
    read WWWUSER

    # configurazione
    if [ -n "$WWWUSER" ]; then
        usermod -g www-data $WWWUSER
    fi

else

    # help
    echo "$0 <cartella> <branch>"

fi

# valore di uscita
exit $?
