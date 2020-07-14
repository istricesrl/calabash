#!/bin/bash

# UTILIZZO
# scrive su un file l'elenco delle pagine di un sito

# verifico i parametri
if [ -n "$2" ]; then

    # log
    logger "$0 $1 $2"

    # scarico l'elenco delle pagine
    wget --spider --force-html -r -l2 $1 2>&1 \
        | grep '^--' | awk '{ print $3 }' \
        | grep -v '\.\(css\|js\|png\|gif\|jpg\)$' \
        | sort -h | uniq > $2

else

    # sinossi
    echo "$0 URL FILE"

fi

# uscita
exit 0

# REVISIONI
# 2020-07-03 controllo funzionamento su Debian 10 (buster)
#            verificato che lo script possa essere lanciato in maniera sicura senza parametri
