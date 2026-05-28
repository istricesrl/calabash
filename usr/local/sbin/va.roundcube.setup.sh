#!/bin/bash

# installazione servizi
va.lamp.setup.sh
va.dovecot.setup.sh
apt-get install roundcube

# REVISIONI
# 2020-07-02 controllo funzionamento su Debian 10 (buster)
