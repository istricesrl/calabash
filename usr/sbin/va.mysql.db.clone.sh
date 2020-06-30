#!/bin/bash

# NOTA
# clona un database su un altro

# log
logger "$0 $1 $2"

# controllo i parametri
if [[ -n $1 ]] && [[ -n $2 ]]; then

    # esporto il database di partenza
    DUMPFILE=$( va.mysql.db.export.sh "$1" /tmp )

    # importo il file sul database di destinazione
    va.mysql.db.import.sh $DUMPFILE "$2"

else

    # help
    echo "$0 [nomedbsorgente] [nomedbdestinazione]"

fi

# valore di uscita
exit $?
