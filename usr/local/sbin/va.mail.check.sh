#!/bin/bash

if [ -n "$1" ]; then

    MAIL=$1

elif [ -f /root/.profile.conf ]; then

    . /root/.profile.conf

else

    echo "il file /root/.profile.conf non esiste"

    exit 1

fi

# pulisco le code di timing
rm -rf /var/spool/exim/db/retry
rm -rf /var/spool/exim/db/retry.lockfile
rm -rf /var/spool/exim/db/wait-remote_smtp_smarthost
rm -rf /var/spool/exim/db/wait-remote_smtp_smarthost.lockfile

# riavvio del servizio
/etc/init.d/exim4 restart

# invio una mail standard di test
echo "prova da $(hostname -f)" | mail -s "test della posta (Debian $(lsb_release -cs))" $MAIL

exit 0
