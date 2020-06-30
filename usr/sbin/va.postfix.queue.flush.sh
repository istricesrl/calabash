#!/bin/bash

# NOTA
# svuota le code di Postfix

# log
logger "$0"

# svuoto
postsuper -d ALL

# esco con il valore di ritorno dell'ultimo comando eseguito
exit $?
