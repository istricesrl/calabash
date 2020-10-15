#!/bin/bash

if [ -n "$1" ]; then

    useradd -d $3 -g $4 -p $(echo $2 | openssl passwd -1 -stdin) $1

else

    echo "$0 utente password home gruppo"

fi
