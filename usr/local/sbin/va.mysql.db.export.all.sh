#!/bin/bash

# UTILIZZO
# esporta tutti i database del server, ognuno nel suo file SQL, in una cartella
# <destinazione>/mysql.all.<timestamp>/ con un MANIFEST delle impronte; e' il backup
# da ripristinare, quindi il dump e' fedele ( AUTO_INCREMENT, DEFINER, routine,
# trigger ed eventi restano come sono ): per i cloni di sviluppo, che vogliono il
# dump ripulito, c'e' va.mysql.db.export.sh
#
# se un database non si esporta ( p.es. una vista rotta ) lo script lo dice su
# stderr, lo riesporta con --force in <db>.forzato.sql ( gli oggetti rotti saltati,
# i dati salvi ), va avanti con gli altri ed esce con 1: da cron l'errore arriva per posta;
# con [giorni] toglie le cartelle mysql.all.* piu' vecchie, ma solo se ogni database ha
# i suoi dati, cosi' un backup che fallisce non cancella quelli buoni

# verifico i parametri
if [[ -n $1 ]]; then

    # log
    logger "$0 $*"

    # cartella di destinazione, compressione, modalita' e retention
    DEST="${1%/}"
    case $2 in
	gz|z)	CMP="gzip -c";	DEC="gzip -dc";	EXT=".gz";	apt-get install -qq -y gzip	&> /dev/null ;;
	bz2|j)	CMP="bzip2 -c";	DEC="bzip2 -dc";	EXT=".bz2";	apt-get install -qq -y bzip2	&> /dev/null ;;
	*)	CMP="cat";	DEC="cat";	EXT="" ;;
    esac
    MODO="$3"
    GIORNI="$4"

    # un giro alla volta
    exec 200>/var/lock/$(basename $0).lock
    if ! flock -n 200; then
	echo "$0: un altro export e' gia' in corso" >&2
	exit 1
    fi

    # cartella del giro, leggibile solo da root
    CARTELLA="$DEST/mysql.all.$(va.txt.timestamp.compressed.sh)"
    mkdir -p "$CARTELLA" && chmod 700 "$CARTELLA" || exit 1

    # elenco dei database
    DATABASES=$( mysql --defaults-extra-file=/etc/mysql.conf -u root -NBe "SHOW DATABASES;" ) || exit 1

    # esporto ogni database: i forzati hanno i dati senza gli oggetti rotti, i falliti niente
    FORZATI=0
    FALLITI=0
    for DB in $DATABASES; do

	# i database di sistema non si esportano
	case $DB in
	    information_schema|performance_schema|sys|lost+found) continue ;;
	esac

	# esporto il database controllando ogni pezzo della pipe
	FILE="$CARTELLA/$DB.sql$EXT"
	/usr/bin/mysqldump --defaults-extra-file=/etc/mysql.conf -u root \
	    --opt --single-transaction --quick --routines --triggers --events --hex-blob \
	    --max_allowed_packet=512M --databases "$DB" 2> "$CARTELLA/$DB.err" | $CMP > "$FILE"
	STATI=( "${PIPESTATUS[@]}" )

	# il dump completo finisce con la riga "-- Dump completed"
	if [[ ${STATI[0]} -ne 0 || ${STATI[1]} -ne 0 ]] || ! $DEC "$FILE" | tail -n 1 | grep -q '^-- Dump completed'; then
	    echo "$0: export di $DB fallito: $(head -c 500 "$CARTELLA/$DB.err")" >&2
	    # secondo tentativo con --force, che salta gli oggetti rotti: i dati ci sono, l'errore resta
	    rm -f "$FILE"
	    FILE="$CARTELLA/$DB.forzato.sql$EXT"
	    /usr/bin/mysqldump --defaults-extra-file=/etc/mysql.conf -u root \
		--opt --single-transaction --quick --routines --triggers --events --hex-blob \
		--max_allowed_packet=512M --force --databases "$DB" 2>> "$CARTELLA/$DB.err" | $CMP > "$FILE"
	    STATI=( "${PIPESTATUS[@]}" )
	    if [[ ${STATI[1]} -eq 0 ]] && $DEC "$FILE" | tail -n 1 | grep -q '^-- Dump completed'; then
		FORZATI=$(( FORZATI + 1 ))
	    else
		echo "$0: anche l'export forzato di $DB e' fallito" >&2
		mv "$FILE" "$CARTELLA/$DB.incompleto.sql$EXT"
		FALLITI=$(( FALLITI + 1 ))
	    fi
	else
	    rm -f "$CARTELLA/$DB.err"
	fi

    done

    # impronte dei file, per verificarli dopo una copia
    ( cd "$CARTELLA" && sha256sum *.sql$EXT > MANIFEST.sha256 2> /dev/null )
    chmod 600 "$CARTELLA"/*

    # esito del giro: OK se tutto e' pulito, FORZATI se qualche database ha oggetti rotti
    [[ $FALLITI -eq 0 && $FORZATI -eq 0 ]] && touch "$CARTELLA/OK"
    [[ $FORZATI -gt 0 ]] && echo "$FORZATI" > "$CARTELLA/FORZATI"
    if [[ $FALLITI -eq 0 ]]; then
	# retention: solo cartelle del giro, e solo se ogni database ha i suoi dati
	if [[ -n $GIORNI ]]; then
	    find "$DEST" -mindepth 1 -maxdepth 1 -type d -name 'mysql.all.*' -mtime +"$GIORNI" -exec rm -rf {} +
	fi
    fi

    # se lo script non sta girando in modalita' silenziosa scrivo la cartella creata
    if [[ "$MODO" != "quiet" ]]; then
	echo -n "$CARTELLA"
    fi

    # uscita
    [[ $FALLITI -eq 0 && $FORZATI -eq 0 ]]
    exit $?

else

    # help
    echo "utilizzo: $0 <percorsoAssolutoDestinazione> [z|j] [quiet|verbose] [giorniDiRetention]"

fi

# NOTE
#
# --single-transaction		le tabelle InnoDB si leggono senza lock, con una fotografia coerente; le MyISAM no
# --quick			legge le righe una alla volta, senza tenerle in memoria
# --routines --triggers --events	funzioni, procedure, trigger ed eventi dello scheduler
# --hex-blob			i campi binari in esadecimale, che non si rovinano col charset
# --databases			mette CREATE DATABASE e USE nel file, che si ripristina da solo
# --force solo al secondo tentativo: una vista rotta ferma il dump e lo si viene a sapere, poi si salvano i dati
#
# SUGGERIMENTO
# per un backup notturno con sette giorni di retention, in /etc/cron.d/:
#
# 0 3 * * * root nice ionice -c3 va.mysql.db.export.all.sh /var/backups/mysql z quiet 7
#
