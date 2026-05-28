#!/bin/bash

# NOTA
# monta un device temporaneamente

# log
logger "$0 $1 $2"

# verifica dei parametri
if [ -n "$1" ]; then

    if [ -z "$2" ]; then
	MOUNTPOINT=/mnt/$(basename $1)
    else
	MOUNTPOINT=$2
    fi

    mkdir -p $MOUNTPOINT

    mount -t auto $1 $MOUNTPOINT

    clear

    df -h

    echo "smonta il device quando hai finito con: umount $MOUNTPOINT"

else

    echo "utilizzo: $0 /path/to/device /path/to/mountpoint"

fi

# valore di uscita
exit $?
