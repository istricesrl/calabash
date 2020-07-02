#!/bin/bash

# se è specificato un dominio
if [ -n "$1" ]; then

    # aggiunta dominio
    mysql --defaults-file=/etc/mysql.conf -u root -e "INSERT INTO mailserver.virtual_domains ( id, name ) VALUES ( NULL, '$1');"

else

    echo "$0 dominio"

fi

# REVISIONI
# 2020-07-02 controllo funzionamento su Debian 10 (buster)
