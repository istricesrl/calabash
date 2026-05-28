#!/bin/bash

NUM=""

declare -i COUNTER

if [[ -n "$2" ]]; then

    MOD="$2"

else

    MOD="+1"

fi

if [[ -n "$1" ]]; then

    if [[ -f "$1" ]]; then

	OLD=$(cat $1)
	NUM=$(va.txt.trim.sh $OLD)

    fi

    if [[ -z "$NUM" ]]; then
	NUM=0
    fi

    COUNTER="$NUM$MOD"
    NUM=$(echo $COUNTER)

    echo $NUM > $1

else

    echo "$0 <path/to/file> [modificatore]"
    echo "es. ~/test \"+3\""

fi

exit 0
