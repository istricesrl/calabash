#!/bin/bash

# verifico che il file esista
if [[ -e "$1" ]]; then

    # log
    logger "$0 $1"

    # backup del file
    cp "$1" "$1.$( va.txt.timestamp.compressed.sh )"

fi

# uscita
exit $?
