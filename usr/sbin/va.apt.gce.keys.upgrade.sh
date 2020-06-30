#!/bin/bash

# NOTA
# aggiorna le chiavi del repository Google Compute Engine

# log
logger "$0"

# aggiorno
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

# journal
va.log.journal.sh "aggiornamento chiavi GCE"

# valore di uscita
exit $?
