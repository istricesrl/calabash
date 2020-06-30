#!/bin/bash

# NOTA
# elimina i file più vecchi di $2 giorni dal path $1

# log
logger "$0 $1 $2"

# controllo i parametri
if [[ -n $1 ]] && [[ -n $2 ]]; then

    # elimino i file vecchi
    find $1 -mtime +$2 -delete

else

    # help
    echo "$0 <percorso> <giorni>"

fi

# valore di uscita
exit $?

# NOTA
# 
