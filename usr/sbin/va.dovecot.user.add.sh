#!/bin/bash

# se è specificato un utente
if [ -n "$1" ]; then

    # richiesta password
    # TODO leggere la password come $2
    echo -n "password: "
    read PASW

    # richiesta dominio
#    # TODO ricavare il dominio dalla mail
#    echo -n "ID dominio: "
#    read DOMID
    echo -n "dominio: "
    read DOM

    va.dovecot.domain.add.sh $DOM

    # aggiunta utente
#    mysql --defaults-file=/etc/mysql.conf -u root -e "INSERT INTO mailserver.virtual_users ( id, domain_id, password, email ) VALUES ( NULL, '$DOMID', ENCRYPT('password','$PASW'), '$1');"

    # TODO
    # creare utente exim4 OPPURE collegare exim4 al database?

    echo "$1:$(doveadm pw -s SHA256-CRYPT -p $PASW)" >> /etc/vmail/$DOM/passwd
    echo "$1@$DOM:$(mkpasswd -m sha-512 '$PASW')" >> /etc/exim4/passwd && service exim4 restart

else

    echo "$0 utente password dominio"
    # TODO implementare gli altri parametri

fi

# REVISIONI
# 2020-07-02 controllo funzionamento su Debian 10 (buster)
