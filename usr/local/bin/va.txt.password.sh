#!/bin/bash

# controllo che sia installato pwgen
apt-get -qq install pwgen

# restituisco la timestamp in formato AAAA-MM-DD HH:MM:SS
echo -n $(pwgen -nc 12)
