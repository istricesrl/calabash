#!/bin/bash

# UTILIZZO
# crea una copia di sicurezza di un file

# verifico che il file esista
if [[ -e "$1" ]]; then

    # log
    logger "$0 $1"

    # backup del file
    cp "$1" "$2$1.$( va.txt.timestamp.compressed.sh )"

else

    # sinossi
    echo "$0 FILE [/PATH/TO/BACKUP/]"

fi

# uscita
exit $?

# REVISIONI
# 2020-07-03 controllo funzionamento su Debian 10 (buster)
#            verificato che lo script possa essere lanciato in maniera sicura senza parametri
