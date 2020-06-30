#!/bin/bash

# riferisco sulla distribuzione e sulla versione del sistema
va.sys.version.show.sh

# spaziatore
echo

# controllo aggiornamenti
if [ -f "/etc/va.apt.upgrade.timestamp" ]; then

    # timestamp aggiornamenti
    TS="$(cat /etc/va.apt.upgrade.timestamp)"
    LAST=$(date '+%s' -d "${TS:0:8} ${TS:8:2}:${TS:10:2}:${TS:12:2}")

    # timestamp corrente
    NOW=$(date '+%s')

    # differenza
    DIFF=`expr $NOW - $LAST`
    DAYS=`expr $DIFF / 68400`

else

    # default per innescare l'aggiornamento
    DAYS=999

fi

# se sono passati troppi giorni, avviso
if [ $DAYS -gt 6 ]; then
    echo "devi aggiornare il sistema"
else
    echo "sistema aggiornato"
fi
