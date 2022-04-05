#!/bin/bash

# NOTA
# crea un nuovo sito in Apache2

# log
logger "$0"


# se ho tutti i parametri
if [ -n "$4" ]; then

    # assegnazioni
    FOLDER="$1"
    DOCUMENT_ROOT="$1"
    URL_SITO="$2"
    ALIAS_SITO="$3"
    MAIL_ADMIN="$4"

    # creo la document root
    mkdir -p "/var/www/$FOLDER"

    # permessi della document root (-rwxrwxr-x)
#    chown -R www-data:www-data "/var/www/$FOLDER"
#    chmod -R 775 "/var/www/$FOLDER"

    # cartella dei log
    LOG_FOLDER="/var/log/apache2/$URL_SITO"

    # creo la cartella dei log
    mkdir -p $LOG_FOLDER

    # permessi della cartella dei log (-rwxrwxr-x)
    chown -R www-data:www-data $LOG_FOLDER
    chmod -R 775 $LOG_FOLDER

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

else

    echo "$0 cartella dominio alias mail"

fi

# uscita
exit $?
