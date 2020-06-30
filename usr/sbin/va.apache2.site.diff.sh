#!/bin/bash

if [ -n "$1" ]; then
    DIR1=/var/www/$1
else
    DIR1=$(pwd)
fi

if [ -n "$2" ]; then
    DIR2=/var/www/$2
else
    DIR2=$DIR1
fi

if [ -n "$3" ]; then
    STAGE1=$3
else
    STAGE1=test
fi

if [ -n "$4" ]; then
    STAGE2=$4
else
    STAGE2=stable
fi

diff -r -u \
    -x '_external' \
    -x '_usr' \
    -x 'etc' \
    -x 'var' \
    -x 'tmp' \
    -x 'config.json' \
    -x 'Dockerfile' \
    -x '.dockerignore' \
    -x '.git' \
    -x '.gitignore' \
    -x 'robots.txt' \
    -x 'composer.lock' \
    -x 'sitemap.xml' \
    -x 'sitemap.csv' \
    -x 'google*.html' \
    $DIR1/$STAGE1 $DIR2/$STAGE2 > ./diff.log

#else
#    echo "$0 nomeCartellaDeploySorgenteSenzaVarWww [nomeCartellaDeployDestinazioneSenzaVarWww] [stageSorgente] [stageDestinazione]"
#fi

# NOTA per avere solo la cartella corrente $(basename $( pwd ) )
