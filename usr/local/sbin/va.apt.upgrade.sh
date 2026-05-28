#!/bin/bash

# NOTA
# pulisce la cache di apt, aggiorna i pacchetti e rimuove i pacchetti orfani

# log
logger "$0"

# pulisco la cache		# aggiorno gli indici		# aggiorno i pacchetti		# elimino i pacchetti orfani
apt-get -qq clean		&& apt-get -qq update		&& apt-get -qq upgrade		&& apt-get -qq autoremove

# registro la timestamp di aggiornamento
echo $(va.txt.timestamp.compressed.sh) > /etc/va.apt.upgrade.timestamp

# journal
va.log.journal.sh "aggiornamento del sistema"

# riferisco sulla distribuzione e sulla versione del sistema
va.sys.version.show.sh

# valore di uscita
exit $?

# NOTA
# -qq rende apt silenzioso
