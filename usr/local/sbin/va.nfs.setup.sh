#!/bin/bash

# NOTA
# installa Apache2, PHP, MySQL

# log
logger "$0"

# dimensioni della finestra di whiptail
VMOD=10
HMOD=70

# chiedo l'autorizzazione a procedere
whiptail	--title "setup server NFS" \
		--yesno "Questo script ti guiderà nel setup di un server NFS. Vuoi procedere?" \
		$VMOD $HMOD

# procedo
if [[ "$?" -eq 0 ]]; then

    # installazione pacchetti
    apt-get install nfs-kernel-server nfs-common

    # file di configurazione
    CONF="/etc/exports"

    # backup configurazione
    va.bak.sh "$CONF"
    echo -n > "$CONF"

    # cartella da esportare
    # TODO chiedere all'utente con un ciclo
    FOLDER="/var/dati/export"
    SUBNET="10.8.0.0/14"
    mkdir -p "$FOLDER"
    chown nobody:nogroup "$FOLDER"
    chmod 755 "$FOLDER"
    echo "$FOLDER	$SUBNET(rw,sync,no_subtree_check)" >> "$CONF"
    echo "$FOLDER	10.240.0.0/24(rw,sync,no_subtree_check)" >> "$CONF"
    echo "$FOLDER	10.132.0.0/20(rw,sync,no_subtree_check)" >> "$CONF"

    # riavvio del server
    service nfs-kernel-server restart

fi

# uscita
exit $?
