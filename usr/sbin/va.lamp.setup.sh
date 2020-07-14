#!/bin/bash

# NOTA
# installa Apache2, PHP, MySQL

# log
logger "$0"

# dimensioni della finestra di whiptail
VMOD=10
HMOD=70

# chiedo l'autorizzazione a procedere
whiptail	--title "setup server LAMP" \
		--yesno "Questo script ti guiderà nel setup di un server web LAMP. Vuoi procedere?" \
		$VMOD $HMOD

# procedo
if [[ "$?" -eq 0 ]]; then

    # installazione di Apache2
    apt-get install apache2

    # risoluzione errore AH00558
    cp /usr/share/doc/va.script/examples/etc/apache2/conf-enabled/servername.conf /etc/apache2/conf-enabled/servername.conf

    # installazione di apachetop
    apt-get install apachetop

    # attivazione del modulo rewrite
    a2enmod rewrite

    # attivazione del modulo expires
    a2enmod expires

    # attivazione del modulo headers
    a2enmod headers

    # installazione di PHP
    apt-get install php

    # installazione di composer
    apt-get install composer

    # installazione degli strumenti di sviluppo
    apt-get install php-dev

    # installazione di PEAR
    apt-get install php-pear

    # installazione di CURL
    apt-get install php-curl

    # installazione di SSH
    apt-get install php-ssh2

    # installazione di GD
    apt-get install php-gd

    # installazione libreria per xml
    apt-get install php-xml

    # installazione di memcache
    apt-get install memcached
    apt-get install php-memcache

    # installazione di redis
    apt-get install redis-server
    apt-get install php-redis

    # installazione di php-zip
    apt-get install php-zip

    # installazione di certbot
    # apt-get install python-certbot-apache -t stretch-backports
    apt-get install python-certbot-apache

    # aggiornamento automatico certificati
    cp /usr/share/doc/va.script/examples/etc/cron.monthly/certbot /etc/cron.monthly/certbot

    # MySQL
    whiptail	--title "MySQL" \
		--yesno "MySQL è il server di database della piattaforma LAMP. Vuoi installare MySQL?" \
		$VMOD $HMOD

    # procedo
    if [[ "$?" -eq 0 ]]; then

	# password di root del server MySQL
	TITLE="password di root per MySQL"
	TEXT="Inserisci una password robusta per l'utente root del server MySQL."
	DEFAULT=""
	MY_ROOT_PW=$(whiptail --title "$TITLE" --inputbox "$TEXT" $VMOD $HMOD "$DEFAULT" 3>&1 1>&2 2>&3)

	# file di configurazione per i programmi tipo mysql
	FILECONF=/etc/mysql.conf

	# backup dei files di configurazione coinvolti
	va.bak.sh $FILECONF

	# impostazione del file di configurazione
	echo "[client]" > $FILECONF
	echo "password=$MY_ROOT_PW" >> $FILECONF

	# permessi (-rw-r--r--)
	chown root:root $FILECONF
	chmod 644 $FILECONF

	# installazione di MySQL
	# Debian 9 apt-get install mysql-server
	apt-get install mariadb-server

	# installazione di mysqltuner
	apt-get install mysqltuner

	# installazione di Percona toolkit
	apt-get install percona-toolkit

	# installazione di MySQL utilities
	apt-get install mysql-utilities

	# NOTA mytop non esiste più in Debian Stable,
	# in alternativa utilizzare?

	# installazione di MySQL per PHP
	apt-get install php-mysql

	# installazione di Adminer (sostituto di phpMyAdmin in Debian 10)
	apt-get install adminer
	echo "Alias /adminer /usr/share/adminer/adminer" > /etc/apache2/conf-enabled/adminer.conf

	# installazione e configurazione di tzdata
	apt-get install tzdata
	mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql --defaults-file=/etc/mysql.conf -u root --force mysql

	# consento l'accesso remoto per root
	mysql --defaults-extra-file=/etc/mysql.conf -u root -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$MY_ROOT_PW');"
	mysql --defaults-extra-file=/etc/mysql.conf -u root -e "UPDATE mysql.user SET plugin = '' WHERE user = 'root';"

	# NOTA
	# questo passaggio dell'attivazione dell'utente root è ancora da testare, comunque i comandi da dare sono questi due qui
	# (provati da linea di comando) va soltanto controllato che funzionino anche da script :-/
	# poi sembra che dopo un po' il server MySQL si perda il settaggio... verificare anche questo x-P

	# riavvio il servizio
	service mysql restart

    fi

    # PostgreSQL
    whiptail	--title "supporto per PostgreSQL" \
		--yesno "PostgreSQL è un database relazionale ad alte prestazioni. Vuoi installare PostgreSQL?" \
		$VMOD $HMOD

    # procedo
    if [[ "$?" -eq 0 ]]; then

	# installazione del server
	apt-get install postgresql

	# installazione di PhpPgAdmin
	apt-get install phppgadmin

	# file di configurazione per i programmi tipo mysql
	FILECONF=/etc/phppgadmin/config.inc.php

	# backup dei files di configurazione coinvolti
	va.bak.sh $FILECONF

	# impostazione del file di configurazione
	echo "<?php" > $FILECONF
	echo "        \$conf['servers'][0]['desc'] = 'PostgreSQL';" >> $FILECONF
	echo "        \$conf['servers'][0]['host'] = 'localhost';" >> $FILECONF
	echo "        \$conf['servers'][0]['port'] = 5432;" >> $FILECONF
	echo "        \$conf['servers'][0]['sslmode'] = 'allow';" >> $FILECONF
	echo "        \$conf['servers'][0]['defaultdb'] = 'template1';" >> $FILECONF
	echo "        \$conf['servers'][0]['pg_dump_path'] = '/usr/bin/pg_dump';" >> $FILECONF
	echo "        \$conf['servers'][0]['pg_dumpall_path'] = '/usr/bin/pg_dumpall';" >> $FILECONF
	echo "        \$conf['default_lang'] = 'auto';" >> $FILECONF
	echo "        \$conf['autocomplete'] = 'default on';" >> $FILECONF
	echo "        \$conf['extra_login_security'] = false;" >> $FILECONF
	echo "        \$conf['owned_only'] = false;" >> $FILECONF
	echo "        \$conf['show_comments'] = true;" >> $FILECONF
	echo "        \$conf['show_advanced'] = false;" >> $FILECONF
	echo "        \$conf['show_system'] = false;" >> $FILECONF
	echo "        \$conf['min_password_length'] = 1;" >> $FILECONF
	echo "        \$conf['left_width'] = 200;" >> $FILECONF
	echo "        \$conf['theme'] = 'default';" >> $FILECONF
	echo "        \$conf['show_oids'] = false;" >> $FILECONF
	echo "        \$conf['max_rows'] = 30;" >> $FILECONF
	echo "        \$conf['max_chars'] = 50;" >> $FILECONF
	echo "        \$conf['use_xhtml_strict'] = false;" >> $FILECONF
	echo "        \$conf['help_base'] = 'http://www.postgresql.org/docs/%s/interactive/';" >> $FILECONF
	echo "        \$conf['ajax_refresh'] = 3;" >> $FILECONF
	echo "        \$conf['plugins'] = array();" >> $FILECONF
	echo "        \$conf['version'] = 19;" >> $FILECONF
	echo "?>" >> $FILECONF

	# permessi (-rw-r--r--)
	chown root:root $FILECONF
	chmod 644 $FILECONF

	# file di configurazione per i programmi tipo mysql
	FILECONF=/etc/apache2/conf-available/phppgadmin.conf

	# backup dei files di configurazione coinvolti
	va.bak.sh $FILECONF

	# impostazione del file di configurazione
	echo "Alias /phppgadmin /usr/share/phppgadmin" > $FILECONF
	echo "<Directory /usr/share/phppgadmin>" >> $FILECONF
	echo "<IfModule mod_dir.c>" >> $FILECONF
	echo "  DirectoryIndex index.php" >> $FILECONF
	echo "</IfModule>" >> $FILECONF
	echo "AllowOverride All" >> $FILECONF
	echo "<IfModule mod_php.c>" >> $FILECONF
	echo "  php_flag magic_quotes_gpc Off" >> $FILECONF
	echo "  php_flag track_vars On" >> $FILECONF
	echo "</IfModule>" >> $FILECONF
	echo "<IfModule !mod_php.c>" >> $FILECONF
	echo "  <IfModule mod_actions.c>" >> $FILECONF
	echo "    <IfModule mod_cgi.c>" >> $FILECONF
	echo "      AddType application/x-httpd-php .php" >> $FILECONF
	echo "      Action application/x-httpd-php /cgi-bin/php" >> $FILECONF
	echo "    </IfModule>" >> $FILECONF
	echo "    <IfModule mod_cgid.c>" >> $FILECONF
	echo "      AddType application/x-httpd-php .php" >> $FILECONF
	echo "      Action application/x-httpd-php /cgi-bin/php" >> $FILECONF
	echo "    </IfModule>" >> $FILECONF
	echo "  </IfModule>" >> $FILECONF
	echo "</IfModule>" >> $FILECONF
	echo "</Directory>" >> $FILECONF

	# permessi (-rw-r--r--)
	chown root:root $FILECONF
	chmod 644 $FILECONF

    fi

    # MSSQL
    whiptail	--title "supporto per MSSQL" \
		--yesno "Desideri installare il supporto per MSSQL in PHP?" \
		$VMOD $HMOD

    # procedo
    if [[ "$?" -eq 0 ]]; then

#apt-get install curl wget apt-transport-https
#apt-get install unixodbc unixodbc-bin unixodbc-dev freetds-common freetds-bin unixodbc php7.0-sybase
#curl https://www.dotdeb.org/dotdeb.gpg | apt-key add -
#echo "deb http://packages.dotdeb.org stretch all" >> /etc/apt/sources.list
#echo "deb-src http://packages.dotdeb.org stretch all" >> /etc/apt/sources.list
#apt-get update
#apt-get install php7.0 php-pear php7.0-dev php7.0-xml
#curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
#curl https://packages.microsoft.com/config/debian/8/prod.list > /etc/apt/sources.list.d/mssql-release.list
#apt-get install locales
#echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
#locale-gen
#wget https://github.com/Microsoft/msphpsql/raw/master/ODBC%2017%20binaries%20preview/Debian%209/msodbcsql_17.0.0.5-1_amd64.deb
#wget https://github.com/Microsoft/msphpsql/raw/master/ODBC%2017%20binaries%20preview/Debian%209/mssql-tools_17.0.0.5-1_amd64.deb
#dpkg -i msodbcsql_17.0.0.5-1_amd64.deb
#dpkg -i mssql-tools_17.0.0.5-1_amd64.deb
#apt-get update
#ACCEPT_EULA=Y apt-get install msodbcsql
#pear config-set php_ini `php --ini | grep "Loaded Configuration" | sed -e "s|.*:\s*||"` system
#pecl install sqlsrv
#pecl install pdo_sqlsrv
#apt-get install libapache2-mod-php7.0 apache2
#a2dismod mpm_event
#a2enmod mpm_prefork
#a2enmod php7.0
#echo "extension=sqlsrv.so" >> /etc/php/7.0/apache2/php.ini
#echo "extension=pdo_sqlsrv.so" >> /etc/php/7.0/apache2/php.ini
#curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list > /etc/apt/sources.list.d/mssql-tools.list
#apt-get update
#apt-get -q install msodbcsql mssql-tools
#echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile
#echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
#source ~/.bashrc
#systemctl restart apache2
#echo "[ODBC Driver 13 for SQL Server]" >> /etc/odbcinst.ini
#echo "Description=Microsoft ODBC Driver 17 for SQL Server" >> /etc/odbcinst.ini
#echo "Driver=/opt/microsoft/msodbcsql/lib64/libmsodbcsql-17.0.so.0.5" >> /etc/odbcinst.ini
#echo "UsageCount=1" >> /etc/odbcinst.ini

## https://docs.microsoft.com/it-it/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server
## https://docs.microsoft.com/it-it/sql/connect/php/loading-the-php-sql-driver
## https://github.com/Microsoft/msphpsql/tree/master/ODBC%2017%20binaries%20preview
## https://github.com/Microsoft/msphpsql/tree/dev#install-unix
## https://coderwall.com/p/21uxeq/connecting-to-a-mssql-server-database-with-php-on-ubuntu-debian
## https://framework.zend.com/blog/2017-02-14-php-sql-server-linux.html
## https://blogs.msdn.microsoft.com/dilkushp/2014/06/11/install-sql-odbc-driver-on-suse-linux/
## https://www.linuxquestions.org/questions/linux-software-2/making-db-queries-from-linux-to-windows-using-python-pyodbc-4175594193/

	echo "non ancora implementato"

    fi

    # Nginx
    whiptail	--title "Nginx reverse proxy" \
		--yesno "Desideri installare il reverse proxy Nginx?" \
		$VMOD $HMOD

    # procedo
    if [[ "$?" -eq 0 ]]; then

	# TODO
	# qui avvisare prima l'utente di sgomberare la porta 80 e aspettare che l'abbia fatto

	# TODO
	# qui per sicurezza riavviare Apache

	# Nginx
	apt-get install nginx nginx-extras -y

    fi

    # riavvio apache
    service apache2 restart

    # journal
    va.log.journal.sh "completata configurazione server LAMP"

fi

# uscita
exit $?
