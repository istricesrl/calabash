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

# elimino i vecchi backup
va.disk.file.old.delete.sh /var/backups 45

# elimino i vecchi temporanei
va.disk.file.old.delete.sh /tmp 15

# pulizia di apt
apt-get clean
apt-get autoremove

# valore di uscita
exit $?
