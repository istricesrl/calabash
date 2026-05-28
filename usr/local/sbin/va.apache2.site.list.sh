#!/bin/bash

for cfile in $(ls /etc/apache2/sites-enabled/*.conf | grep -v '\-le\-ssl'); do

    NAME="$(cat $cfile | grep ServerName)"
    NAME="${NAME##* }"

    if [ "$1" == "" -o "$1" == "$NAME" ]; then

        echo "file di configurazione: $cfile"

        if [ -n "$(cat $cfile | grep ServerName)" ]; then echo "$(cat $cfile | grep ServerName)"; fi
        if [ -n "$(cat $cfile | grep ServerAlias)" ]; then echo "$(cat $cfile | grep ServerAlias)"; fi
        if [ -n "$(cat $cfile | grep DocumentRoot)" ]; then echo "$(cat $cfile | grep DocumentRoot)"; fi
        if [ -n "$(cat $cfile | grep CustomLog)" ]; then echo "$(cat $cfile | grep CustomLog)"; fi

        DROOT=$(cat $cfile | grep DocumentRoot)
        DROOT="${DROOT##* }"

        if [ -f $DROOT/_etc/_current.conf ]; then

            echo "	versione del framework: $(cat $DROOT/_etc/_current.conf)"

        else

            echo "	versione del framework: nessuna"

        fi

        echo

    fi

done
