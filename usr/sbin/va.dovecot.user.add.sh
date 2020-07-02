#!/bin/bash

# se è specificato un utente
if [ -n "$1" ]; then

    # richiesta password
    # TODO leggere la password come $2
    echo -n "password: "
    read PASW

    # richiesta dominio
    # TODO ricavare il dominio dalla mail
    echo -n "ID dominio: "
    read DOMID

    # aggiunta utente
    mysql --defaults-file=/etc/mysql.conf -u root -e "INSERT INTO mailserver.virtual_users ( id, domain_id, password, email ) VALUES ( NULL, '$DOMID', ENCRYPT('password','$PASW'), '$1');"

    # TODO
    # creare utente exim4 OPPURE collegare exim4 al database?

else

    echo "$0 email"

fi

# REVISIONI
# 2020-07-02 controllo funzionamento su Debian 10 (buster)
