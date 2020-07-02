#!/bin/bash

# NOTA
# installa postfix, mailutils, pfqueue

# log
logger "$0"

# dimensioni della finestra di whiptail
VMOD=10
HMOD=70

# inizio setup
whiptail	--title "setup di postfix e del relay di posta" \
		--yesno "Questo script ti guiderà nel setup di postfix, del relay di posta e dei pacchetti collegati. Vuoi procedere?" \
		$VMOD $HMOD

if [[ "$?" -eq 0 ]]; then

    # postfix
    apt-get install postfix mailutils pfqueue

    # file di configurazione da modificare
    FILECONF=/etc/postfix/main.cf

    # backup dei files di configurazione coinvolti
    va.bak.sh $FILECONF

    # hostname del sistema
    TITLE="hostname"
    TEXT="Inserire il nome host del sistema:"
    SMTP_HOSTNAME=$(whiptail --title "$TITLE" --inputbox "$TEXT" $(($VMOD*2)) $(($HMOD+5)) "$(cat /etc/mailname)" 3>&1 1>&2 2>&3)

    # destinazioni
    TITLE="destinazioni"
    TEXT="Inserire i nomi host delle destinazioni di posta:"
    SMTP_DESTINATIONS=$(whiptail --title "$TITLE" --inputbox "$TEXT" $(($VMOD*2)) $(($HMOD+5)) "$(cat /etc/mailname), localhost" 3>&1 1>&2 2>&3)

    # relay
    TITLE="relay"
    TEXT="Inserire il nome host per l'SMTP relay (ad es. [smtp-relay.gmail.com]:587 per le istanze VM di Google via Google Apps o [rhun.videoarts.eu]:10008 per il relay via Rhun)"
    SMTP_RELAY=$(whiptail --title "$TITLE" --inputbox "$TEXT" $(($VMOD*2)) $(($HMOD+5)) "" 3>&1 1>&2 2>&3)

    # informo l'utente
    whiptail	--title "configurazione del relay" \
		--msgbox "Se si è impostato un relay, ricordarsi di aggiungere l'ip pubblico di questa macchina (ad es. x.x.x.x/32) alle reti autorizzate (mynetworks) di postfix, e di autorizzarlo sul firewall se presente... FALLO ADESSO!" \
		$VMOD $HMOD

    # informo l'utente
    whiptail	--title "nota per il relay tramite Google Apps" \
		--msgbox "Se si è impostato come relay Google Apps, ricordarsi di configurare l'inoltro SMTP nel dominio di pertinenza (NOTA: in questo modo si possono inviare mail solo dagli indirizzi appartenenti al dominio di pertinenza)" \
		$VMOD $HMOD

    # impostazione del file di configurazione
    echo "biff = no" >> $FILECONF
    echo "myorigin = /etc/mailname" > $FILECONF
    echo "mydomain = $SMTP_HOSTNAME" >> $FILECONF
    echo "myhostname = $SMTP_HOSTNAME" >> $FILECONF
    echo "mydestination = $SMTP_DESTINATIONS" >> $FILECONF
    echo "mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128" >> $FILECONF
    echo "append_dot_mydomain = no" >> $FILECONF
    echo "alias_maps = hash:/etc/aliases" >> $FILECONF
    echo "alias_database = hash:/etc/aliases" >> $FILECONF
    echo "mailbox_size_limit = 0" >> $FILECONF
    echo "recipient_delimiter = +" >> $FILECONF
    echo "inet_interfaces = all" >> $FILECONF
    echo "inet_protocols = ipv4" >> $FILECONF
    echo "readme_directory = no" >> $FILECONF
    echo "smtpd_banner = \$myhostname ESMTP \$mail_name (Debian/GNU)" >> $FILECONF
    echo "smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem" >> $FILECONF
    echo "smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key" >> $FILECONF
    echo "smtpd_use_tls=yes" >> $FILECONF
    echo "smtpd_tls_session_cache_database = btree:${data_directory}/smtpd_scache" >> $FILECONF
    echo "smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache" >> $FILECONF
    echo "smtp_tls_security_level = may" >> $FILECONF
    echo "relayhost = $SMTP_RELAY" >> $FILECONF

    # autenticazione
    TITLE="autenticazione"
    TEXT="Se il relay SMTP scelto supporta l'autenticazione, inserire i dati nella forma username:password, altrimenti lasciare il campo vuoto"
    SMTP_AUTH=$(whiptail --title "$TITLE" --inputbox "$TEXT" $(($VMOD)) $(($HMOD+5)) "" 3>&1 1>&2 2>&3)

    if [[ -n "$SMTP_AUTH" ]]; then

	echo "$SMTP_RELAY $SMTP_AUTH" >> /etc/postfix/sasl_passwd
	postmap /etc/postfix/sasl_passwd
	# rm -f /etc/postfix/sasl_passwd

	echo "smtp_sasl_auth_enable = yes" >> $FILECONF
	echo "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd" >> $FILECONF
	echo "smtp_sasl_security_options = noanonymous" >> $FILECONF
	echo "header_size_limit = 4096000" >> $FILECONF

    fi

    # permessi (-rw-r--r--)
    chown root:root $FILECONF
    chmod 644 $FILECONF

    # riavvio postfix
    service postfix restart

    # mail di test
    while : ; do

	whiptail	--title "mail di test" \
			--yesno "vuoi inviare una mail di test?" \
			$VMOD $HMOD

	if [[ "$?" -eq 0 ]]; then

	    va.postfix.mail.sh

	    sleep 5

	    whiptail	--title "log dell'invio" \
			--msgbox "$( tail /var/log/mail.log )" \
			$((VMOD*4)) $((HMOD*2))

	else

	    break

	fi

    done

fi

# esco con il valore di ritorno dell'ultimo comando eseguito
exit $?

# REVISIONI
# 2020-07-02 controllo funzionamento su Debian 10 (buster)
