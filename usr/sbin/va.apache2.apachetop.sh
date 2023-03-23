#!/bin/bash

# NOTA
# crea una nuova CSR in Apache2

# log
logger "$0"

LOGFILES=""

if [ -n "$1" ]; then

    for i in $( find /var/log/apache2/ -name 'access.log' ); do
        if [ "$( echo $i | grep $1 )" != "" ]; then

            LOGFILES="$LOGFILES -f $i"

        fi
    done

    apachetop $LOGFILES

else

    echo "$0 sito"

fi

