#!/bin/bash

# NOTA
# installa memcache

# log
logger "$0"

# installazione del pacchetto
apt-get install memcached

# file di configurazione
FILECONF=/etc/memcached.conf

# backup dei files di configurazione coinvolti
va.bak.sh $FILECONF

# impostazione del file di configurazione
echo "-d" > $FILECONF
echo "logfile /var/log/memcached.log" >> $FILECONF
echo "-m 512" >> $FILECONF
echo "-p 11211" >> $FILECONF
echo "-u memcache" >> $FILECONF
echo "-l 127.0.0.1" >> $FILECONF

# permessi (-rw-r--r--)
chown root:root $FILECONF
chmod 644 $FILECONF

# scarico phpmemcachedadmin
wget http://blog.elijaa.org/wp-content/uploads/2016/09/phpMemcachedAdmin.tar.gz

# creo la cartella
mkdir -p /usr/share/phpmemcachedadmin

# scompatto il tar in /usr/share/phpmemcachedadmin
tar -xvf ./phpMemcachedAdmin.tar.gz --strip-components=1 -C /usr/share/phpmemcachedadmin

# NOTA
# l'opzione -C indica la cartella dove scompattare, mentre
# l'opzione --strip-components indica il numero di livelli da escludere dal percorso originario
# quest'ultima serve per evitare che i file vengano scompattati in
# /usr/share/phpmemcachedadmin/phpmemcachedadmin perché i file nel tar si trovano già in una
# cartella che si chiama phpmemcachedadmin

# permessi (-rwxrwxr-x)
chown -R root:www-data /usr/share/phpmemcachedadmin
chmod -R 775 /usr/share/phpmemcachedadmin

# elimino il tar
rm -f ./phpMemcachedAdmin.tar.gz

# credenziali per l'accesso alle statistiche
PASW=$(pwgen -nc 12)
USER="root"

# creo il file .htaccess
htpasswd -bc /usr/share/phpmemcachedadmin/.htpasswd $USER $PASW

# log
va.log.journal.sh "credenziali per phpmemcachedadmin $USER : $PASW"

# file di configurazione
FILECONF=/etc/apache2/conf-enabled/phpmemcachedadmin.conf

# backup dei files di configurazione coinvolti
va.bak.sh $FILECONF

# impostazione del file di configurazione
echo "Alias /phpmemcachedadmin /usr/share/phpmemcachedadmin" > $FILECONF
echo "<Directory /usr/share/phpmemcachedadmin>" >> $FILECONF
echo "    Order allow,deny" >> $FILECONF
echo "    Allow from all" >> $FILECONF
echo "    Options None" >> $FILECONF
echo "    AllowOverride all" >> $FILECONF
echo "    AuthUserFile /usr/share/phpmemcachedadmin/.htpasswd" >> $FILECONF
echo "    AuthName \"PhpMemcachedAdmin\"" >> $FILECONF
echo "    AuthType Basic" >> $FILECONF
echo "    require valid-user" >> $FILECONF
echo "    <IfModule mod_expires.c>" >> $FILECONF
echo "        ExpiresActive On" >> $FILECONF
echo "        ExpiresDefault M310" >> $FILECONF
echo "    </IfModule>" >> $FILECONF
echo "</Directory>" >> $FILECONF

# permessi (-rw-r--r--)
chown root:root $FILECONF
chmod 644 $FILECONF

# riavvio apache2
service apache2 restart

# questo script non è funzionante, è solo una collezione di appunti
exit 1

# NOTA
# il parametro -m rappresenta la memoria a disposizione del demone e viene settato inizialmente
# a 512 Mb; va modificato in seguito a seconda delle risorse disponibili e delle esigenze
# della macchina
