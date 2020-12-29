#!/bin/bash

# NOTA
# crea una nuova CSR in Apache2

# log
logger "$0"

LOGFILES=""

for i in $( find /var/log/apache2/ -name 'access.log' ); do

    LOGFILES="$LOGFILES -f $i"

done

apachetop $LOGFILES
