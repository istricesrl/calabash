#!/bin/bash

# NOTA
# crea un nuovo sito in Apache2

# log
logger "$0"

# dimensioni della finestra di whiptail
VMOD=10
HMOD=70

# chiedo l'autorizzazione a procedere
whiptail	--title "configurazione di exim4" \
		--yesno "Questo script ti guiderà nella configurazione di exim4. Vuoi procedere?" \
		$VMOD $HMOD

# procedo
if [[ "$?" -eq 0 ]]; then

    # nome host
    TITLE="nome host"
    TEXT="Inserisci il nome host completo della macchina (ad es. mail.dominio.tld):"
    DEFAULT="$(hostname -d)"
    NOMEHOST=$(whiptail --title "$TITLE" --inputbox "$TEXT" $VMOD $HMOD "$DEFAULT" 3>&1 1>&2 2>&3)

    # nome relay
    TITLE="relay SMTP"
    TEXT="Inserisci il nome host completo di porta del relay SMTP da usare:"
    DEFAULT="smtp.sendgrid.net::2525"
    NOMERELAY=$(whiptail --title "$TITLE" --inputbox "$TEXT" $VMOD $HMOD "$DEFAULT" 3>&1 1>&2 2>&3)

    # utente relay
    TITLE="utente relay SMTP"
    TEXT="Inserisci il nome utente del relay SMTP da usare:"
    DEFAULT="apikey"
    USERRELAY=$(whiptail --title "$TITLE" --inputbox "$TEXT" $VMOD $HMOD "$DEFAULT" 3>&1 1>&2 2>&3)

    # password relay
    TITLE="password relay SMTP"
    TEXT="Inserisci la password del relay SMTP da usare:"
    DEFAULT=""
    PASSWRELAY=$(whiptail --title "$TITLE" --inputbox "$TEXT" $VMOD $HMOD "$DEFAULT" 3>&1 1>&2 2>&3)

    # TODO chiedere se la macchina fa da server o no
    # SE FA DA SERVER
    # ...
    # ALTRIMENTI

    # file di configurazione
    FILECONF=/etc/exim4/update-exim4.conf.conf

    # backup del file di configurazione
    va.bak.sh $FILECONF

    # scrittura del file di configurazione
    echo "dc_eximconfig_configtype='smarthost'" > $FILECONF
    echo "dc_other_hostnames=''" >> $FILECONF
    echo "dc_local_interfaces='127.0.0.1'" >> $FILECONF
    echo "dc_readhost='$NOMEHOST'" >> $FILECONF
    echo "dc_relay_domains=''" >> $FILECONF
    echo "dc_minimaldns='false'" >> $FILECONF
    echo "dc_relay_nets=''" >> $FILECONF
    echo "dc_smarthost='$NOMERELAY'" >> $FILECONF
    echo "dc_use_split_config='false'" >> $FILECONF
    echo "dc_hide_mailname='true'" >> $FILECONF
    echo "dc_mailname_in_oh='true'" >> $FILECONF
    echo "dc_localdelivery='mail_spool'" >> $FILECONF
    echo >> $FILECONF
    echo "CFILEMODE='644'" >> $FILECONF

    # file di configurazione
    FILECONF=/etc/exim4/passwd.client

    # backup del file di configurazione
    va.bak.sh $FILECONF

    # scrittura del file di configurazione
    echo "*:$USERRELAY:$PASSWRELAY" > $FILECONF

fi

# riavvio del servizio
/etc/init.d/exim4 restart






















exit 0

# NOTA probabilmente lo script funziona per l'installazione di un server relay
# però per il semplice invio della posta sembra avere problemi

# TODO rifare lo script prendendo spunto dalla configurazione delle webXX.istricesrl.it

# installazione servizi
apt-get install exim4 sasl2-bin swaks libnet-ssleay-perl

# creazione certificato auto firmato
apt-get install certbot
certbot certonly --standalone -d $(hostname)

# TODO se il nome host non contiene punti, certbot non funziona
# in questo caso chiedere l'hostname all'utente!

# utente vmail
sudo groupadd -g 5000 vmail
sudo useradd -g vmail -u 5000 vmail -d /var/mail
sudo chown -R vmail:vmail /var/mail

# permessi per i certificati
adduser Debian-exim sasl
groupadd privkey_users
usermod -aG privkey_users Debian-exim
chmod g+rx /etc/letsencrypt/live/
chmod g+rx /etc/letsencrypt/archive/
chmod g+rx /etc/letsencrypt/archive/$(hostname)/
chmod g+r /etc/letsencrypt/archive/$(hostname)/*.pem
chown root:privkey_users /etc/letsencrypt/archive/
chown root:privkey_users /etc/letsencrypt/archive/$(hostname)/
chown root:privkey_users /etc/letsencrypt/archive/$(hostname)/*.pem
chown root:privkey_users /etc/letsencrypt/live/
chown root:privkey_users /etc/letsencrypt/live/$(hostname)/

# file di configurazione
FILECONF=/etc/exim4/exim4.conf.localmacros

# backup del file di configurazione
va.bak.sh $FILECONF

# scrittura del file di configurazione
echo "MAIN_TLS_ENABLE = true" > $FILECONF
echo "AUTH_SERVER_ALLOW_NOTLS_PASSWORDS = true" >> $FILECONF
echo "MAIN_TLS_CERTIFICATE = /etc/letsencrypt/archive/$(hostname)/fullchain1.pem" >> $FILECONF
echo "MAIN_TLS_PRIVATEKEY = /etc/letsencrypt/archive/$(hostname)/privkey1.pem" >> $FILECONF

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
FILECONF=/etc/exim4/exim4.conf.template

# backup del file di configurazione
va.bak.sh $FILECONF

# scrittura del file di configurazione
cp /usr/share/doc/va.script/examples/etc/exim4/exim4.conf.template.full $FILECONF

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
# provare swaks -a -tls -q HELO -s mail.istricesrl.it -au test -p 2525 -ap '<>'

# REVISIONI
# 2020-07-02 controllo funzionamento su Debian 10 (buster)
