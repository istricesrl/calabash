#!/bin/bash

logger "$0"

/usr/share/doc/exim4-base/examples/exim-adduser

echo "$( cat /etc/exim4/passwd | sort -h )" > /etc/exim4/passwd

chown root:Debian-exim /etc/exim4/passwd
chmod 640 /etc/exim4/passwd

update-exim4.conf

/etc/init.d/exim4 restart

# NOTA
# in alternativa:
# echo "<nomeUtente>:$(mkpasswd -m sha-512 '<password>')" >> /etc/exim4/passwd && service exim4 restart
