#!/bin/bash

# NOTA
# importa un file SQL in un database

# log
logger "$0"

# controllo i parametri
if [[ -n $1 ]] && [[ -n $2 ]] && [[ -n $3 ]]; then

    # creo il database
    mysql --defaults-file=/etc/mysql.conf -u root -e "CREATE DATABASE IF NOT EXISTS \`$1\` CHARACTER SET utf8 COLLATE utf8_unicode_ci;"

    # creo l'utente
    mysql --defaults-file=/etc/mysql.conf -u root -e "CREATE USER \`$2\`@\`%\` IDENTIFIED BY '$3';"

    # assegno i privilegi
    mysql --defaults-file=/etc/mysql.conf -u root -e "GRANT ALL PRIVILEGES ON \`$1\`.* TO \`$2\`@\`%\`;"

else

    # help
    echo "$0 nomedb userdb password"

fi

# valore di uscita
exit $?
