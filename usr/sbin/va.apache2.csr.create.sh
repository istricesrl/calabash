#!/bin/bash

# NOTA
# crea una nuova CSR in Apache2

# log
logger "$0"

# dimensioni della finestra di whiptail
VMOD=10
HMOD=70

# chiedo l'autorizzazione a procedere
whiptail	--title "creazione nuova CSR" \
		--yesno "Questo script ti guiderà nella creazione di una nuova CSR. Vuoi procedere?" \
		$VMOD $HMOD

# procedo
if [[ "$?" -eq 0 ]]; then

    # url del sito
    TITLE="dominio da certificare"
    TEXT="Inserisci il dominio da certificare (ad es. domain.tld) oppure l'host (ad es. host.domain.tld):"
    DEFAULT=""
    DOMINIO=$(whiptail --title "$TITLE" --inputbox "$TEXT" $VMOD $HMOD "$DEFAULT" 3>&1 1>&2 2>&3)

    # informo l'utente
    whiptail	--title "ATTENZIONE" \
		--msgbox "Come 'common name' inserire l'indirizzo del sito comprensivo di www, oppure inserire l'asterisco al posto di www per i certificati wildcard." \
		$VMOD $HMOD

    mkdir -p /etc/apache2/ssl/$DOMINIO/
    openssl req -new -newkey rsa:2048 -nodes -keyout /etc/apache2/ssl/$DOMINIO/$DOMINIO.key -out /etc/apache2/ssl/$DOMINIO/$DOMINIO.csr

    cat /etc/apache2/ssl/$DOMINIO/$DOMINIO.csr

    touch /etc/apache2/ssl/$DOMINIO/$DOMINIO.crt
    touch /etc/apache2/ssl/$DOMINIO/$DOMINIO.bnd.crt

fi

# uscita
exit $?

# NOTA
# 
