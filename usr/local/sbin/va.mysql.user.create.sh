#!/bin/bash

# NOTA
# importa un file SQL in un database

# log
logger "$0"

# controllo i parametri
if [[ -n $1 ]] && [[ -n $2 ]]; then

    # creo l'utente
    mysql --defaults-file=/etc/mysql.conf -u root -e "CREATE USER \`$1\`@\`%\` IDENTIFIED BY '$2';"

    # se è specificato un database
    if [[ -n $3 ]]; then

	# assegno i privilegi
	mysql --defaults-file=/etc/mysql.conf -u root -e "GRANT ALL PRIVILEGES ON \`$3\`.* TO \`$1\`@\`%\`;"

    fi

else

    # help
    echo "$0 nomedb password [userdb]"

fi

# valore di uscita
exit $?
