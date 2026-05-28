#!/bin/bash

# NOTA
# pulisce il disco liberando spazio

# log
logger "$0"

# elimino i vecchi log
find /var/log -name *.gz -delete
find /var/log -name *.log.* -delete
find /var/log -name *.err.* -delete
find /var/log -name *.info.* -delete
find /var/log -name *.warn.* -delete

# elimino i log dei siti
if [ -d /var/www ]; then
    find /var/www -name *.log -delete
fi

# elimino i vecchi backup
if [ -d /var/backups ]; then
    va.disk.file.old.delete.sh /var/backups 30
fi

# elimino i vecchi temporanei
va.disk.file.old.delete.sh /tmp 15

# pulisco i log di apache
if [ -d /var/log/apache2 ]; then
    for i in $( find /var/log/apache2 -name "access.log" -o -name "error.log" ); do
        echo -n > $i
    done
fi

# pulizia di apt
apt-get clean
apt-get autoremove

# valore di uscita
exit $?
