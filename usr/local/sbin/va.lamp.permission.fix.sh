#!/bin/bash

# NOTA
# risolve la maggior parte dei problemi di permessi sul server web
# ATTENZIONE! non usare questo script su server che hanno configurazioni
# custom dei permessi e dei gruppi

# log
logger "$0 $1"

# se $1 non inizia per slash lo aggiungo
P="$1"; [[ "$P" != /* ]] && P="/$P"

# verifico che le cartelle esistano
if [ -d /var/www$P ]; then

    # resetto i permessi
    find /var/www$P -type d		-not \( -path ".git" -prune \)		-exec echo {} \; -exec chmod 775 {} \;
    find /var/www$P -type f		-not \( -path ".git" -prune \)		-exec echo {} \; -exec chmod 664 {} \;
    find /var/www$P -name '*.sh'	-not \( -path ".git" -prune \)		-exec echo {} \; -exec chmod 775 {} \;

    # resetto proprietario e gruppo
    chown -R www-data:www-data /var/www$P

fi

# uscita
exit $?

# NOTA
# normalmente, quando si creano utenti che devono avere accesso a specifiche
# aree del server web, si assegna loro come gruppo di default www-data in
# modo che possano operare sulle cartelle assegnate; per impedire che possano
# andare in cartelle che non sono di loro competenza si utilizza l'opzione
# apposita del server FTP che "ingabbia" l'utente all'interno della propria home

# NOTA
#
# r -> 4
# w -> 2
# x -> 1
#
# quindi
#
# 7 7 5 <- permessi in formato numerico
# ^ ^ ^
# | | |
# | | +- others (chi non è owner e non è membro di group)	5 = 4 + 1	= read + execute
# | +--- group (chi fa parte del gruppo indicato)		7 = 4 + 2 + 1	= read + write + execute
# +----- owner (il proprietario del file			7 = 4 + 2 + 1	= read + write + execute
#
