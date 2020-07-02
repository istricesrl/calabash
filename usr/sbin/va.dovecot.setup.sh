#!/bin/bash

# installazione servizi
apt-get install dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-mysql

va.mysql.db.import.sh /usr/share/doc/va.script/examples/etc/dovecot/dovecot.sql mailserver

# REVISIONI
# 2020-07-02 controllo funzionamento su Debian 10 (buster)
