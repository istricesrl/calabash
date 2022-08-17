#!/bin/bash

clear

if [ -n "$1" ]; then

    sox $1 -r 8000 -c 1 $2

else

    echo "utilizzo: $0 nomeFileMp3 nomeFileGsm"

fi
