#!/bin/bash

# installazione servizi
apt-get install dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-mysql

#va.mysql.db.import.sh /usr/share/doc/va.script/examples/etc/dovecot/dovecot.sql mailserver

#echo -n "inserisci password per l'utente mailserver: "
#read PASW

#if [ -n "$PASW" ]; then
#    va.mysql.user.create.sh mailserver $PASW mailserver
#fi

sudo groupadd -g 5000 vmail
sudo useradd -g vmail -u 5000 vmail -d /var/mail
sudo chown -R vmail:vmail /var/mail
sudo chown -R vmail:dovecot /etc/dovecot
sudo chmod -R o-rwx /etc/dovecot
usermod -aG privkey_users vmail

# TODO copiare TUTTA la configurazione da /usr/share/doc/va.script/examples/etc/dovecot

# REVISIONI
# 2020-07-02 controllo funzionamento su Debian 10 (buster)
