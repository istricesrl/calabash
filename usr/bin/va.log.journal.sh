#!/bin/bash

# NOTA
# scrive un'annotazione su /root/root.journal

# log
logger "$0"

# scrittura anntotazione
echo "$(va.txt.timestamp.sh) $1" >> /root/root.journal

# uscita
exit $?
