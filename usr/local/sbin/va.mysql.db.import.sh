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
    # salto la riga di sandbox mode presente nei dump di MariaDB recenti (10.11+/11.x),
    # che i client più vecchi non capiscono e fanno fallire l'import alla prima riga
    sed '/enable the sandbox mode/d' "$1" | mysql --defaults-file=/etc/mysql.conf -u root "$2"

elif [[ -n $1 ]]; then

    # importo il file SQL
    # salto la riga di sandbox mode presente nei dump di MariaDB recenti (10.11+/11.x)
    sed '/enable the sandbox mode/d' "$1" | mysql --defaults-file=/etc/mysql.conf -u root

else

    # help
    echo "$0 nomefile [nomedb]"

fi

# valore di uscita
exit $?
