#!/bin/bash

# log
logger "$0 $1 $2 $3"

# controllo i parametri
if [[ -n $1 ]]; then

    # creo la document root
    mkdir -p $1

    # branch di default
    if [[ -z $2 ]]; then
        BRANCH=master
    else
        BRANCH=$2
    fi

    # scarico Glisweb
    wget https://github.com/istricesrl/glisweb/archive/$BRANCH.zip

    # pulisco il nome del file zip dai prefissi
    BRANCHZIP=$( echo $BRANCH | sed -e "s/^feature\///" )
    BRANCHZIP=$( echo $BRANCHZIP | sed -e "s/^hotfix\///" )

    # pulisco il nome della cartella dai prefissi
    BRANCHDIR=${BRANCH////-}

    # scompatto Glisweb
    unzip ./$BRANCHZIP.zip

    # elimino il vecchio framework
    rm -rf $1/_*

    # installo la nuova versione
    # mv -f ./glisweb-$BRANCHDIR/{.,}* ./$1
    cp -rf ./glisweb-$BRANCHDIR/{.[!.],}* $1

    # elimino la vecchia cartella
    rm -rf ./glisweb-$BRANCHDIR
    rm -rf ./$BRANCHDIR.zip

    # installo il .gitignore se è presente un repository .git
    if [ -f $1/_usr/_deploy/_git/.gitignore -a -d $1/.git ]; then
        cp $1/_usr/_deploy/_git/.gitignore $1/.gitignore
    fi

    # aggiorno composer
    cd $1/ && composer update

    # permessi
    $1/_src/_sh/_gw.permissions.reset.sh

    # se l'installazione è interattiva
    if [ -z "$3" ]; then

        # richiesta
        echo -n "vuoi installare l'ambiente LAMP (s/n)? "
        read YN

        # configurazione
        if [ "$YN" = "s" ]; then
            $1/_src/_sh/_gw.environment.setup.sh
        fi

#        # richiesta
#        echo -n "vuoi installare il database del sito (s/n)? "
#        read YN

#        # configurazione
#        if [ "$YN" = "s" ]; then
#            $1/_src/_sh/_gw.mysql.install.sh
#        fi

        # richiesta
        echo -n "vuoi configurare il framework (s/n)? "
        read YN

        # configurazione
        if [ "$YN" = "s" ]; then
            read -p "template di configurazione (base/sviluppo)? " TP
            $1/_src/_sh/_gw.config.sh $TP
        fi

    fi

else

    # help
    echo "$0 <cartella> [branch] [quiet]"

fi

# valore di uscita
exit $?
