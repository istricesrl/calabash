#!/bin/bash

# installazione servizi
apt-get install dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-mysql

va.mysql.db.import.sh /usr/share/doc/va.script/examples/etc/dovecot/dovecot.sql mailserver

echo -n "inserisci password per l'utente mailserver: "
read PASW

if [ -n "$PASW" ]; then
    va.mysql.user.create.sh mailserver $PASW mailserver
fi

# REVISIONI
# 2020-07-02 controllo funzionamento su Debian 10 (buster)
