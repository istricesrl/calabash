#!/bin/bash

if [ -n "$4" ]; then

    SA=$1
    SB=$2
    SC=$3

    MSG="$4"

elif [ -n "$2" ]; then

    . /etc/slack.$1.conf
    MSG="$2"

elif [ -f /etc/slack.conf ]; then

    . /etc/slack.conf
    MSG="$1"
#    ATT=",\"fields\":[{\"title\":\"build.log\",\"value\":\"$(cat /var/www/glisweb.videoarts.eu/build.log)\"}]"

else

    exit 1

fi

curl -s -o /dev/null -X POST -H 'Content-type: application/json' --data "{\"text\":\"$(hostname -f): $MSG\"}" https://hooks.slack.com/services/$SA/$SB/$SC

exit 0
