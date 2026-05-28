#!/bin/bash

# NOTA
# invia una mail tramite il relay di sistema

# log
logger "$0"

# inizializzazioni
VMOD=10
HMOD=70

FROM="root@$( cat /etc/mailname )"

MITTENTE=$(whiptail --title "mittente" --inputbox "Inserisci il mittente della mail di test" $VMOD $HMOD "$FROM" 3>&1 1>&2 2>&3)
DESTINATARIO=$(whiptail --title "destinatario" --inputbox "Inserisci il destinatario della mail di test" $VMOD $HMOD "" 3>&1 1>&2 2>&3)
OGGETTO=$(whiptail --title "oggetto" --inputbox "Inserisci l'oggetto della mail di test" $VMOD $HMOD "mail di test da $FROM" 3>&1 1>&2 2>&3)
TESTO=$(whiptail --title "testo" --inputbox "Inserisci il testo della mail di test" $VMOD $HMOD "Questa è una mail di test da $FROM." 3>&1 1>&2 2>&3)

echo -e "$TESTO" | mail -s "$OGGETTO"  -a "From: $FROM" $DESTINATARIO
