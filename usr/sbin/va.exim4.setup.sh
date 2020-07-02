#!/bin/bash

# installazione servizi
apt-get install exim4 sasl2-bin

# creazione certificato auto firmato
apt-get install certbot
certbot certonly --standalone -d $(hostname)

# file di configurazione
FILECONF=/etc/exim4/exim4.conf.localmacros

# backup del file di configurazione
va.bak.sh $FILECONF

# scrittura del file di configurazione
echo "MAIN_TLS_ENABLE = true" > $FILECONF
echo "AUTH_SERVER_ALLOW_NOTLS_PASSWORDS = true" >> $FILECONF
echo "MAIN_TLS_CERTIFICATE = /etc/letsencrypt/archive/$(hostname)/fullchain3.pem" >> $FILECONF
echo "MAIN_TLS_PRIVATEKEY = /etc/letsencrypt/archive/$(hostname)/privkey3.pem" >> $FILECONF

# file di configurazione
FILECONF=/etc/exim4/update-exim4.conf.conf

# backup del file di configurazione
va.bak.sh $FILECONF

# scrittura del file di configurazione
echo "dc_eximconfig_configtype='smarthost'" > $FILECONF
echo "dc_other_hostnames=''" >> $FILECONF
echo "dc_local_interfaces='127.0.0.1 ; ::1 ; 0.0.0.0.2525'" >> $FILECONF
echo "dc_readhost='$(hostname)'" >> $FILECONF
echo "dc_relay_domains=''" >> $FILECONF
echo "dc_minimaldns='false'" >> $FILECONF
echo "dc_relay_nets=''" >> $FILECONF
echo "dc_smarthost='smtp.sendgrid.net::587'" >> $FILECONF
echo "CFILEMODE='644'" >> $FILECONF
echo "dc_use_split_config='false'" >> $FILECONF
echo "dc_hide_mailname='true'" >> $FILECONF
echo "dc_mailname_in_oh='true'" >> $FILECONF

# richiesta API key Sendgrid
echo -n "inserire l'API key di Sendgrid: "
read APIKEY

# se è stata inserita l'API key
if [ -n "$APIKEY" ]; then

    # file di configurazione
    FILECONF=/etc/exim4/passwd.client

    # backup del file di configurazione
    va.bak.sh $FILECONF

    # scrittura del file di configurazione
    echo "*:apikey:$APIKEY" > $FILECONF

fi

# file di configurazione
FILECONF=/etc/default/saslauthd

# scrittura del file di configurazione
echo "START=yes" > $FILECONF
echo "DESC=\"SASL Authentication Daemon\"" >> $FILECONF
echo "NAME=\"saslauthd\"" >> $FILECONF
echo "MECHANISMS=\"pam\"" >> $FILECONF
echo "MECH_OPTIONS=\"\"" >> $FILECONF
echo "THREADS=5" >> $FILECONF
echo "OPTIONS=\"-c -m /var/run/saslauthd\"" >> $FILECONF

# riavvio del server
update-exim4.conf
service exim4 restart
service saslauthd restart

# mail di test
va.mail.send.sh

# NOTA
# provare anche da https://www.smtper.net/

# REVISIONI
# 2020-07-02 controllo funzionamento su Debian 10 (buster)
