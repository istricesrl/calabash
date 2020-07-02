#!/bin/bash

# se è specificato un dominio
if [ -n "$1" ]; then

    # aggiunta dominio
#    mysql --defaults-file=/etc/mysql.conf -u root -e "INSERT INTO mailserver.virtual_domains ( id, name ) VALUES ( NULL, '$1');"

    # creazione cartella
    mkdir -p /var/mail/vhosts/$1
    mkdir -p /etc/vmail/$1
    touch /etc/vmail/$1/aliases
    touch /etc/vmail/$1/passwd

else

    echo "$0 dominio"

fi

# REVISIONI
# 2020-07-02 controllo funzionamento su Debian 10 (buster)
