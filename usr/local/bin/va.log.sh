#!/bin/bash

# NOTA
# scrive un'annotazione su un file

# log
logger "$0"

# scrittura anntotazione
echo "$(va.txt.timestamp.sh) $1" >> $2

# uscita
exit $?
