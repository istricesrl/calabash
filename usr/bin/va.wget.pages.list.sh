#!/bin/bash

if [ -n "$2" ]; then

    wget --spider --force-html -r -l2 $1 2>&1 \
        | grep '^--' | awk '{ print $3 }' \
        | grep -v '\.\(css\|js\|png\|gif\|jpg\)$' \
        | sort -h | uniq > $2

else

    echo "$0 siteUrl logFile"

fi

exit 0
