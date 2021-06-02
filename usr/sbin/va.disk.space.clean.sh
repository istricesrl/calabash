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
find /var/www -name *.log -delete

# elimino i vecchi backup
va.disk.file.old.delete.sh /var/backups 30

# elimino i vecchi temporanei
va.disk.file.old.delete.sh /tmp 15

# pulisco i log di apache
for i in $( find /var/log/apache2 -name "access.log" -o -name "error.log" ); do
    echo -n > $i
done

# pulizia di apt
apt-get clean
apt-get autoremove

# valore di uscita
exit $?
