#!/bin/bash

# NOTA
# esporta tutti i database presenti sul server, ognuno in un un file SQL,
# li unisce in un archivio tar (eventualmente compresso)

# log
logger "$0 $1 $2 $3"

if [[ -n $1 ]]; then

    # TODO $1 dovrebbe essere passato con slash, per uniformità con va.bak.tar.sh
    # NOTA qui aggiungere slash se manca, poi modificare sotto dove viene usato $1 e
    # anche il commento

    # file temporaneo di appoggio per l'elenco dei database
    dbLst=`mktemp`

    # file temporaneo di appoggio per l'elenco dei file esportati
    sqlLst=`mktemp`

    # leggo l'elenco dei database
    mysql --defaults-extra-file=/etc/mysql.conf -u root -NBe "SHOW DATABASES;" |
	grep -v 'lost+found' |
	grep -v 'information_schema' |
	grep -v 'performance_schema' |
	while read database ; do

	# aggiungo il database all'elenco
	( flock -x 200
	    echo $database >> $dbLst
	) 200>/var/lock/$(basename $0).lockfile

    done

    # scorro l'elenco dei database
    for i in $(cat $dbLst); do

	# se il nome non è vuoto
	if [ -n "$i" ]; then

	    # esporto il database e aggiungo il nome del file esportato all'elenco
	    ( flock -x 200
		echo $(va.mysql.db.export.sh $i /tmp) >> $sqlLst
	    ) 200>/var/lock/$(basename $0).lockfile

	fi

    done

    # opzioni di compressione
    case $2 in
	gz|z)
	    OPT="z"
	    EXT=".gz"
	    apt-get install -qq -y gzip
	;;
	bz2|j)
	    OPT="j"
	    EXT=".bz2"
	    apt-get install -qq -y bzip2
	;;
	*)
	    OPT=""
	    EXT=""
	;;
    esac

    # creo il nome del file di archivio
    destinazione=$1/mysql.all.$(va.txt.timestamp.compressed.sh).sql.tar$EXT

    # aggiungo i file SQL all'archivio
    tar -c$OPT -f $destinazione -T $sqlLst &> /dev/null

    # se lo script non sta girando in modalità silenziosa...
    if [[ "$3" != "quiet" ]]; then

	# ...scrivo il nome del file di archivio
	echo -n $destinazione

    fi

else

    # help
    echo "utilizzo: $0 <percorsoAssolutoDestinazione> [z|j] [quiet|verbose]"

fi

# uscita
exit $?

# NOTE
#
# -T legge i nomi da inserire nell'archivio da un file
#

#
# SUGGERIMENTO
# se si vuole impostare un backup periodico dei database, è facile farlo creando
# nell'apposita cartella /etc/cron.* un file che contenga i comandi:
#
# #!/bin/bash
# va.mysql.db.export.all.sh /var/backups quiet gz
#
