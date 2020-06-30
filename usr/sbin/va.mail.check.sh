#!/bin/bash

# pulisco le code di timing
rm -rf /var/spool/exim/db/retry
rm -rf /var/spool/exim/db/retry.lockfile
rm -rf /var/spool/exim/db/wait-remote_smtp_smarthost
rm -rf /var/spool/exim/db/wait-remote_smtp_smarthost.lockfile

# invio una mail standard di test
echo "prova da $(hostname -f)" | mail -s "test della posta (Debian $(lsb_release -cs))" sistemistica@istricesrl.it
