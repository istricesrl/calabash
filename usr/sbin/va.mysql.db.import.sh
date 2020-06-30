#!/bin/bash

# NOTA
# importa un file SQL in un database

# log
logger "$0"

# controllo i parametri
if [[ -n $1 ]] && [[ -n $2 ]]; then

    # creo il database se non esiste già
    mysql --defaults-file=/etc/mysql.conf -u root -e "CREATE DATABASE IF NOT EXISTS \`$2\` CHARACTER SET utf8 COLLATE utf8_unicode_ci;"

    # importo il database
    mysql --defaults-file=/etc/mysql.conf -u root "$2" < $1

elif [[ -n $1 ]]; then

    # importo il file SQL
    mysql --defaults-file=/etc/mysql.conf -u root < $1

else

    # help
    echo "$0 nomefile [nomedb]"

fi

# valore di uscita
exit $?
