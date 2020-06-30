#!/bin/bash

# NOTA
# parametri:
# $1 -> percorso assoluto della cartella da comprimere
# $2 -> percorso assoluto della cartella di destinazione opzionale
# $3 -> tipo di compressione z|j (gzip o bzip2) opzionale

# log
logger "$0 $1 $2 $3 $4"

# se lo script viene chiamato senza parametri, scrivo l'help
if [ -z "$1" ]; then
    echo "$0 SOURCE [DEST] [z|j] [quiet]"
    exit 0
fi

# se non viene fornito un nome, lo creo a partire dal percorso
DSTFILE=/tmp/$(va.txt.backslash.to.dot.sh $1).$(va.txt.timestamp.compressed.sh).tar

# se la compressione richiesta è gzip, controllo che il pacchetto sia installato e aggiungo .gz
if [ "$3" = "z" ]; then
    apt-get install gzip > /dev/null 2>&1
    DSTFILE=$DSTFILE.gz
    COMPRES="-$3"
fi

# se la compressione richiesta è bzip2, controllo che il pacchetto sia installato e aggiungo .bz2
if [ "$3" = "j" ]; then
    apt-get install bzip2 > /dev/null 2>&1
    DSTFILE=$DSTFILE.bz2
    COMPRES="-$3"
fi

# comprimo la cartella
tar -c $COMPRES -f $DSTFILE $1 > /dev/null 2>&1

# se è specificato un percorso di destinazione, sposto il file
if [ -n "$2" ]; then
    mv $DSTFILE $2 > /dev/null 2>&1
fi

# uscita
exit $?

# NOTA
# -c crea l'archivio
# -f specifica il nome del file
# -z compressione gzip
# -j compressione bzip2

# NOTA
# per ottenere un backup periodico, creare degli script in /etc/cron.* contenenti
# semplicemente una o più chiamate a questo script, ad esempio:
#
# #!/bin/bash
# va.bak.tar.sh /var/www /var/backups/ z
#
# NOTA
# il secondo parametro (destinazione) può essere sia una cartella (termina per /)
# sia un file (eventualmente con percorso), nel caso si necessiti di assegnare al
# backup un nome arbitrario
#
# NOTA
# per aggiungere slash -> [[ "${STR}" != */ ]] && STR="${STR}/"
