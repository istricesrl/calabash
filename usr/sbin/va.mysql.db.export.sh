#!/bin/bash

# NOTA
# esporta un database un un file SQL

# log
logger "$0 $1 $2 $3"

if [[ -n $1 ]]; then

    # TODO anche qui considerare la questione dello slash finale (vedi gli altri script)

    # creo il nome del file di destinazione
    destinazione="$2/$1.$(va.txt.timestamp.compressed.sh).sql"

    # esporto il database
    /usr/bin/mysqldump --defaults-extra-file=/etc/mysql.conf --opt --max_allowed_packet=512M --routines --single-transaction --events -u root "$1" \
    | sed 's/ AUTO_INCREMENT=[0-9]*\b//g' | grep -v '^--' | grep -v -e '^[[:space:]]*$' \
    | sed -E 's/DEFINER=`[a-z0-9]+`@`[a-z0-9\.%]+`/DEFINER=CURRENT_USER()/g' | sed 's/ AUTO_INCREMENT=[0-9]*\b//g' > $destinazione

    # PRIMA ERA | sed 's/ AUTO_INCREMENT=[0-9]*\b//g' | grep -v '^--' | grep -v '^\/\*' | grep -v -e '^[[:space:]]*$' \

    # se lo script non gira in modalità silenziosa...
    if [[ "$3" != "quiet" ]]; then

	# ...scrivo il nome del file creato
	echo -n $destinazione

    fi

else

    # help
    echo "$0 <nomeDb> <percorsoAssolutoDestinazione> [quiet|verbose]"

fi

# uscita
exit $?

# NOTE
#
# --opt				è una scorciatoia per:
#   --add-drop-table		cancella le tabelle se esistono prima di crearle
#   --add-locks			acquisisce il lock prima di inserire le righe
#   --create-options		include tutte le opzioni in CREATE TABLE
#   --disable-keys		genera gli indici dopo aver inserito tutte le righe
#   --extended-insert		usa la sintassi multiriga per le insert
#   --lock-tables		acquisisce il lock prima di leggere le tabelle
#   --quick			legge i dati per riga anziché tutti insieme
#   --set-charset		aggiunge SET NAMES al file SQL
# --routines			include le stored procedures e functions
# --single-transaction		racchiude l'intero file in una singola transazione
# --events			include gli eventi dello scheduler
