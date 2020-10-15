#!/bin/bash

# NOTA
# crea un nuovo sito in Apache2

# log
logger "$0"

# dimensioni della finestra di whiptail
VMOD=10
HMOD=70

# chiedo l'autorizzazione a procedere
whiptail	--title "creazione nuovo sito" \
		--yesno "Questo script ti guiderà nella creazione di un nuovo sito in Apache2. Vuoi procedere?" \
		$VMOD $HMOD

# procedo
if [[ "$?" -eq 0 ]]; then

    # avviso DNS
    whiptail	--title "creazione dei record DNS" \
		--infobox "Hai creato i record DNS per il sito che stai per creare? È caldamente consigliato farlo ORA!" \
		$VMOD $HMOD

    # url del sito
    TITLE="URL del sito"
    TEXT="Inserisci l'URL principale del sito, per esempio www.sito.tld se sai già quale sarà il dominio di produzione oppure sito.agenzia.tld se ancora non lo sai"
    DEFAULT=""
    URL_SITO=$(whiptail --title "$TITLE" --inputbox "$TEXT" $VMOD $HMOD "$DEFAULT" 3>&1 1>&2 2>&3)

    # alias del sito
    TITLE="alias del sito"
    TEXT="Inserisci gli alias del sito separati da spazio"
    DEFAULT=""
    ALIAS_SITO=$(whiptail --title "$TITLE" --inputbox "$TEXT" $VMOD $HMOD "$DEFAULT" 3>&1 1>&2 2>&3)

    # e-mail dell'amministratore
    TITLE="mail dell'amministratore"
    TEXT="Inserisci l'indirizzo e-mail dell'amministratore del sito"
    DEFAULT="sistemistica@$URL_SITO"
    MAIL_ADMIN=$(whiptail --title "$TITLE" --inputbox "$TEXT" $VMOD $HMOD "$DEFAULT" 3>&1 1>&2 2>&3)

    # cartella del sito
    TITLE="cartella principale"
    TEXT="Inserisci il percorso dove si trovano le versioni del sito; viene proposta la cartella corrispondente all'URL principale, ma se stai creando una nuova versione all'interno di un sito già esistente dovresti indicare la cartella dove vuoi posizionare la versione"
    DEFAULT="$URL_SITO"
    FOLDER=$(whiptail --title "$TITLE" --inputbox "$TEXT" $VMOD $HMOD "$DEFAULT" 3>&1 1>&2 2>&3)

    # document root
    TITLE="document root"
    TEXT="Inserisci il percorso dove si trovano i file del sito"
    # DEFAULT="0.0.1"
    DEFAULT="test"
    DROOT="$(whiptail --title "$TITLE" --inputbox "$TEXT" $VMOD $HMOD "$DEFAULT" 3>&1 1>&2 2>&3)"
    DOCUMENT_ROOT="$FOLDER/$DROOT"

    # creo la document root
    mkdir -p "/var/www/$DOCUMENT_ROOT"

    # link simbolico
    # TITLE="alias della document root"
    # TEXT="Inserisci l'alias per il percorso dove si trovano i file del sito"
    # DEFAULT="test"
    # DALIAS="$(whiptail --title "$TITLE" --inputbox "$TEXT" $VMOD $HMOD "$DEFAULT" 3>&1 1>&2 2>&3)"

    # creo l'eventuale alias
    if [[ -n "$DALIAS" ]]; then
	DOCUMENT_ROOT_ALIAS="$FOLDER/$DALIAS"
	ln -s "/var/www/$DOCUMENT_ROOT" "/var/www/$DOCUMENT_ROOT_ALIAS"
	DOCUMENT_ROOT=$DOCUMENT_ROOT_ALIAS
    fi

    # permessi della document root (-rwxrwxr-x)
    chown -R www-data:www-data "/var/www/$FOLDER"
    chmod -R 775 "/var/www/$FOLDER"

    # cartella dei log
    #OLD LOG_FOLDER="/var/www/$DOCUMENT_ROOT/var/log"
    LOG_FOLDER="/var/log/apache2/$URL_SITO"

    # creo la cartella dei log
    mkdir -p $LOG_FOLDER

    # permessi della cartella dei log (-rwxrwxr-x)
    chown -R www-data:www-data $LOG_FOLDER
    chmod -R 775 $LOG_FOLDER

    # repository git
    if [ "$(basename $DOCUMENT_ROOT)" = "test" -o "$(basename $DOCUMENT_ROOT)" = "dev" ]; then
	whiptail	--title "creazione repository Git" \
			--yesno "Vuoi creare un repository Git locale per questo sito?" \
			$VMOD $HMOD
	if [[ "$?" -eq 0 ]]; then
	    cd "/var/www/$DOCUMENT_ROOT"
	    git init
	fi
    fi

    # file di configurazione
    FILECONF="/etc/apache2/sites-available/$URL_SITO.conf"

    # scrittura del file di configurazione
    echo "<VirtualHost *:80>" > $FILECONF
    echo >> $FILECONF
    echo "	ServerAdmin $MAIL_ADMIN" >> $FILECONF
    echo "	ServerName $URL_SITO" >> $FILECONF
    if [[ -n $ALIAS_SITO ]]; then
	echo "	ServerAlias $ALIAS_SITO" >> $FILECONF
    fi
    echo >> $FILECONF
    echo "	DocumentRoot /var/www/$DOCUMENT_ROOT" >> $FILECONF
    echo >> $FILECONF
    echo "	<Directory />" >> $FILECONF
    echo "		Options FollowSymLinks" >> $FILECONF
    echo "		AllowOverride All" >> $FILECONF
    echo "	</Directory>" >> $FILECONF
    echo >> $FILECONF
    echo "	<Directory /var/www/$DOCUMENT_ROOT/>" >> $FILECONF
    echo "		Options Indexes FollowSymLinks MultiViews" >> $FILECONF
    echo "		AllowOverride All" >> $FILECONF
    echo "		Order allow,deny" >> $FILECONF
    echo "		allow from all" >> $FILECONF
    echo "	</Directory>" >> $FILECONF
    echo >> $FILECONF
    echo "	LogLevel warn" >> $FILECONF
    echo "	ErrorLog $LOG_FOLDER/error.log" >> $FILECONF
    echo "	CustomLog $LOG_FOLDER/access.log combined" >> $FILECONF
    echo >> $FILECONF
    echo "</VirtualHost>" >> $FILECONF

    # permessi (-rw-r--r--)
    chown root:root $FILECONF
    chmod 644 $FILECONF

    # attivazione del sito
    a2ensite $(basename $FILECONF)

    # riavvio apache
    service apache2 restart

    # certificato HTTPS
    whiptail	--title "creazione certificato HTTPS" \
		--yesno "Vuoi creare un certificato HTTPS per questo sito?" \
		$VMOD $HMOD
    if [[ "$?" -eq 0 ]]; then
	DOMAINS=""
	for DOMAIN in $ALIAS_SITO; do
	    DOMAINS+=" -d $DOMAIN"
	done
	echo "creo un certificato per: -d $URL_SITO $DOMAINS"
	certbot --apache -d $URL_SITO $DOMAINS
    fi

    # utente FTP
    whiptail	--title "creazione utente FTP" \
		--yesno "Vuoi creare un utente FTP per questo sito?" \
		$VMOD $HMOD
    if [[ "$?" -eq 0 ]]; then

	# password
	TITLE="password per l'utente"
	TEXT="Inserisci una password sicura per l'utente (suggerita $(pwgen -nyc 16 1))"
	USERPW="$(whiptail --title "$TITLE" --inputbox "$TEXT" $VMOD $HMOD "$DEFAULT" 3>&1 1>&2 2>&3)"
	DOCUMENT_ROOT="$FOLDER/$DROOT"

	# creazione utente
	va.user.add.sh $(echo $URL_SITO | awk -F[\.\.] '{print $2}') $USERPW /var/www/$DOCUMENT_ROOT www-data

    fi

fi

# uscita
exit $?

# NOTA
# il vecchio script aveva la possibilità di creare utenti FTP e database collegati al sito
# in un secondo momento sarebbe bello reimplementarla

# NOTA
# normalmente l'assetto dei siti in fase iniziale di sviluppo sulla macchina di hosting condiviso è il seguente
#
# SVILUPPO
#  URL del sito: nomesito.agenzia.tld
#   -> file di configurazione creato: nomesito.agenzia.tld.conf
#  mail dell'amministratore: sistemistica@agenzia.tld
#  cartella principale: nomesito.agenzia.tld
#  document root: 0.0.1
#   -> document root creata: /var/www/nomesito.agenzia.tld/0.0.1
#  alias document root: test
#   -> alias document root creato: /var/www/nomesito.agenzia.tld/test
#  cartella di log: nomesito.agenzia.tld/test
#   -> cartella di log creata: /var/log/apache2/nomesito.agenzia.tld/test
#  database: nomesito_agenzia_tld_test
#
# TEST
#  alias del sito: test.nomesito.tld
#  database: nomesito_tld_test
#
# PRODUZIONE
#  URL del sito: www.nomesito.tld
#   -> file di configurazione creato: www.nomesito.tld.conf
#  alias del sito: nomesito.tld
#  mail dell'amministratore: webmaster@nomesito.tld
#  cartella principale: nomesito.agenzia.tld
#  document root: 1.0.0
#   -> document root creata: /var/www/nomesito.agenzia.tld/1.0.0
#  alias document root: stable
#   -> alias document root creato: /var/www/nomesito.agenzia.tld/stable
#  cartella di log: nomesito.agenzia.tld/stable
#   -> cartella di log creata: /var/log/apache2/nomesito.agenzia.tld/stable
#  database: nomesito_tld_stable
#
