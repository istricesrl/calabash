#!/bin/bash

# NOTA
# crea un database

# log
logger "$0"

# dimensioni della finestra di whiptail
VMOD=10
HMOD=70

# chiedo l'autorizzazione a procedere
whiptail	--title "creazione di un database PostgreSQL" \
		--yesno "Questo script crea un nuovo database PostgreSQL. Vuoi procedere?" \
		$VMOD $HMOD

# procedo
if [[ "$?" -eq 0 ]]; then

    # nome del database
    TITLE="nome del database"
    TEXT="Inserisci il nome del database da creare."
    DEFAULT=""
    DATABASE=$(whiptail --title "$TITLE" --inputbox "$TEXT" $VMOD $HMOD "$DEFAULT" 3>&1 1>&2 2>&3)

    # nome utente
    TITLE="nome utente per il database"
    TEXT="Inserisci il nome per l'utente autorizzato ad operare sul database da creare."
    DEFAULT=$DATABASE
    USERNAME=$(whiptail --title "$TITLE" --inputbox "$TEXT" $VMOD $HMOD "$DEFAULT" 3>&1 1>&2 2>&3)

    # password
    TITLE="password per l'utente $DATABASE"
    TEXT="Inserisci la password per l'utente autorizzato ad operare sul database da creare."
    DEFAULT=$( va.txt.password.sh )
    PASSWORD=$(whiptail --title "$TITLE" --inputbox "$TEXT" $VMOD $HMOD "$DEFAULT" 3>&1 1>&2 2>&3)

    # creazione dell'utente
    sudo -u postgres psql -c "CREATE DATABASE $DATABASE;"

    # creazione dell'utente
    sudo -u postgres psql -c "CREATE USER $USERNAME PASSWORD '$PASSWORD';"

    # privilegi per l'utente
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DATABASE TO $USERNAME;"

fi

# valore di uscita
exit $?
