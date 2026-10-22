#!/bin/bash

# UTILIZZO
# questo script salva in locale gli archivi di un takeout, seguendo l'elenco atteso.txt scritto da
# va.takeout.inventory.sh: i tar e i dump si producono in streaming via ssh, quindi sulla macchina
# di cui si fa il takeout non si scrive niente e non serve spazio libero

# verifico i parametri
if [ -n "$2" ]; then

    # log
    logger "$0 $*"

    # host remoto ( root se non specificato ) e cartella del takeout
    HOST="$1"; [[ "$HOST" != *@* ]] && HOST="root@$HOST"
    DIR="${2%/}"
    shift 2
    SSH="ssh -o BatchMode=yes -o ConnectTimeout=10 -o ServerAliveInterval=30"

    # senza inventario non si sa cosa salvare
    if [ ! -f "$DIR/atteso.txt" ]; then
        echo "KO: manca $DIR/atteso.txt, lanciare prima va.takeout.inventory.sh" >&2
        exit 2
    fi
    umask 077

    # i percorsi extra ( p.es. una cartella di /var/backups ) si aggiungono all'elenco atteso
    for p in "$@"; do
        p="${p#/}"; p="${p%/}"
        f="$(echo "$p" | tr / .).tar.gz"
        grep -q "|$f|" "$DIR/atteso.txt" || echo "extra|$f|$p|$($SSH -n "$HOST" "du -sb '/$p'" 2>/dev/null | cut -f1)" >> "$DIR/atteso.txt"
    done

    # spazio: serve per quello che non c'è ancora
    SERVE=$(while IFS='|' read -r t f s d; do [ -s "$DIR/$f" ] || echo "${d:-0}"; done < "$DIR/atteso.txt" | awk '{s+=$1} END{print s+0}')
    LIB=$(df -B1 --output=avail "$DIR" | tail -1 | tr -d ' ')
    if [ "$LIB" -lt $(( SERVE * 4 / 10 )) ]; then
        echo "KO: servono fino a $(numfmt --to=iec "$SERVE") e in $DIR ne restano $(numfmt --to=iec "$LIB"): lo spazio lo libera il sistemista" >&2
        exit 5
    fi

    # credenziali MySQL scelte dal censimento
    MY=$(sed -n 's/^mysql=//p' "$DIR/meta.txt" 2>/dev/null); [ "$MY" = - ] && MY=

    KO=0
    while IFS='|' read -r -u 3 TIPO FILE SRC DIM; do

        # già scaricato: si riprende da dove ci si era fermati
        if [ -s "$DIR/$FILE" ]; then
            echo "= $FILE"
            continue
        fi

        PART="$DIR/$FILE.part"
        case "$TIPO" in
            tar|extra)
                # tar esce con 1 quando un file cambia mentre lo legge: è un avviso, non un errore
                $SSH -n "$HOST" "tar --numeric-owner --warning=no-file-changed -czpf - -C / '$SRC'" > "$PART"
                RC=$?; [ "$RC" -eq 1 ] && RC=0
                ;;
            tarlist)
                $SSH "$HOST" "tar --numeric-owner --warning=no-file-changed -czpf - -C / -T -" < "$DIR/$SRC" > "$PART"
                RC=$?; [ "$RC" -eq 1 ] && RC=0
                ;;
            db)
                $SSH "$HOST" 'bash -s' > "$PART" <<REMOTO
set -o pipefail
mysqldump $MY --single-transaction --routines --triggers --events --max_allowed_packet=512M --databases '$SRC' | gzip
REMOTO
                RC=$?
                ;;
            users)
                $SSH "$HOST" 'bash -s' > "$PART" <<REMOTO
set -e -o pipefail
{
    echo "-- utente $SRC"
    mysql $MY -N -B -e "select Host from mysql.user where User='$SRC'" | while read -r h; do
        mysql $MY -N -B -r -e "SHOW CREATE USER '$SRC'@'\$h'" < /dev/null 2>/dev/null | sed 's/\$/;/' || true
        mysql $MY -N -B -r -e "SHOW GRANTS FOR '$SRC'@'\$h'" < /dev/null | sed 's/\$/;/'
    done
    echo "-- Grants completed"
} | gzip
REMOTO
                RC=$?
                ;;
            *)
                echo "? $FILE: tipo $TIPO sconosciuto" >&2
                RC=9
                ;;
        esac

        if [ "$RC" -eq 0 ] && [ -s "$PART" ]; then
            mv "$PART" "$DIR/$FILE" && chmod 600 "$DIR/$FILE"
            echo "+ $FILE $(du -h "$DIR/$FILE" | cut -f1)"
        else
            rm -f "$PART"
            echo "KO $FILE ( uscita $RC )" >&2
            KO=$(( KO + 1 ))
        fi

    done 3< "$DIR/atteso.txt"

    # impronte di quello che c'è, per accorgersi più avanti se un archivio si rovina
    ( cd "$DIR" && sha256sum -- *.gz > SHA256SUMS ) && chmod 600 "$DIR/SHA256SUMS"

    echo "archivi: $(ls "$DIR"/*.gz 2>/dev/null | wc -l), totale $(du -sh "$DIR" | cut -f1), errori: $KO"
    [ "$KO" -eq 0 ] || exit 1

else

    # sinossi
    echo "$0 HOST CARTELLA [PERCORSO_EXTRA ...]"

fi

# uscita
exit 0

# REVISIONI
# 2026-10-22 prima versione, nata dal takeout di 35.195.31.8 ( Debian 10 su Google Cloud )

# NOTA
# parametri:
# $1    -> macchina da cui si fa il takeout, con l'utente davanti se non è root ( utente@host )
# $2    -> cartella del takeout preparata da va.takeout.inventory.sh
# $3... -> percorsi extra da salvare, p.es. /var/backups/vecchio-sito: finiscono in var.backups.vecchio-sito.tar.gz
#
# NOTA
# i nomi degli archivi sono il percorso con i punti al posto delle barre: etc.tar.gz, home.mario.tar.gz,
# var.www.sito.tar.gz, var.lib.mysql.DB.sql.gz, var.lib.mysql.users.UTENTE.sql.gz
#
# NOTA
# un archivio già presente non si riscarica: rilanciato dopo un errore, lo script riprende da quello che
# manca; per rifarne uno lo si cancella e si rilancia
#
# NOTA
# i dump sono fedeli ( con commenti, AUTO_INCREMENT e DEFINER originali ) e non passano da
# va.mysql.db.export.sh, che li ripulisce per i cloni di sviluppo; --databases mette nel dump anche
# CREATE DATABASE e USE
#
# NOTA
# SHA256SUMS si calcola sugli archivi arrivati: l'integrità del trasferimento la garantisce il CRC di
# gzip, che va.takeout.verify.sh controlla leggendo ogni archivio per intero
