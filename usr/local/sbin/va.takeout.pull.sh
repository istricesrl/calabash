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
            dbremoto)
                # il database sta su un'altra macchina: lo scarica quella del sito, con le credenziali del sito
                $SSH "$HOST" "bash -s -- '$SRC'" > "$PART" <<'REMOTO'
set -o pipefail
# credenziali di un database su un'altra macchina ( FILE DB HOST [CHIAVE] ), come opzioni [client] per mysql
# e mysqldump: si leggono dalla configurazione del sito e non lasciano mai la sua macchina
# ( la stessa funzione sta in va.takeout.site.inventory.sh e in va.takeout.pull.sh ); CHIAVE è il nome del
# server in src/config.json, perché due server possono avere stesso indirizzo e database e password diverse
cnf() {
    local f="$1" db="$2" h="$3" n="$4" u= p= po= L s
    case "$f" in
        */src/config.json)
            # i deploy glisweb: indirizzo e database in config.json, utente e password in shadow.json
            if command -v python3 >/dev/null; then
                L=$(python3 -c '
import json, os, sys
f, db, h, n = sys.argv[1:]
c = json.load(open(f)).get("mysql", {}).get("servers", {})
s = os.path.join(os.path.dirname(f), "shadow.json")
o = json.load(open(s)).get("mysql", {}).get("servers", {}) if os.path.isfile(s) else {}
for k, v in c.items():
    if isinstance(v, dict) and v.get("db") == db and v.get("address", "") == h and n in ("", k):
        v = dict(v, **o.get(k, {}))
        print("\t".join(str(v.get(x, "")) for x in ("username", "password", "port")))
        break
' "$f" "$db" "$h" "$n" 2>/dev/null)
            else
                s="$(dirname "$f")/shadow.json"; [ -f "$s" ] || s=/dev/null
                L=$(jq -r -s --arg db "$db" --arg h "$h" --arg n "$n" '(.[1].mysql.servers // {}) as $o | .[0].mysql.servers | to_entries[] | select(.value.db == $db and (.value.address // "") == $h and ($n == "" or .key == $n)) | .value + ($o[.key] // {}) | [.username // "", .password // "", .port // ""] | @tsv' "$f" "$s" 2>/dev/null | head -1)
            fi
            IFS=$'\t' read -r u p po <<< "$L"
            ;;
        *)
            # wp-config.php e .env
            kk() { sed -n -E "s/.*define *\( *['\"]$1['\"] *, *['\"]([^'\"]*)['\"].*/\1/p; s/^$2=[\"']?([^\"' ]*).*/\1/p" "$f" | head -1; }
            u=$(kk DB_USER DB_USERNAME); p=$(kk DB_PASSWORD DB_PASSWORD); po=$(kk DB_PORT DB_PORT)
            ;;
    esac
    [[ "$h" == *:* ]] && { po=${h##*:}; h=${h%%:*}; }
    [ -n "$u" ] || return 1
    p=${p//\\/\\\\}; p=${p//\"/\\\"}
    printf '[client]\nhost=%s\nuser=%s\npassword="%s"\n' "$h" "$u" "$p"
    [ -n "$po" ] && printf 'port=%s\n' "$po"
    # mysqldump non conosce connect-timeout: va solo al client mysql, che prova il collegamento
    printf '[mysql]\nconnect-timeout=10\n'
    return 0
}
# eventi e routine vogliono privilegi ( EVENT, SHOW_ROUTINE ) che l'utente di un sito spesso non ha: si prova
# prima, e quello che non si può leggere si salta; stampa le opzioni per mysqldump e quante routine sono illeggibili
limiti() {
    local O="$1" db="$2" E=--events L T=0 K=0
    mysql --defaults-extra-file=<(echo "$O") -N -e "show events from \`$db\`" > /dev/null 2>&1 || E=--skip-events
    L=$(mysql --defaults-extra-file=<(echo "$O") -N -B -e "show function status where Db='$db'; show procedure status where Db='$db'" 2>/dev/null \
        | awk -F'\t' '{printf "show create %s `%s`.`%s`;\n", tolower($3), $1, $2}')
    if [ -n "$L" ]; then
        T=$(wc -l <<< "$L")
        # senza privilegio il corpo torna NULL, o la riga non torna affatto
        K=$(mysql --defaults-extra-file=<(echo "$O") --force -N -B <<< "$L" 2>/dev/null | awk -F'\t' '$3 != "NULL"' | wc -l)
    fi
    if [ "$K" -eq "$T" ]; then echo "$E --routines 0"; else echo "$E --skip-routines $(( T - K ))"; fi
}
IFS='#' read -r f db h n <<< "$1"
O=$(cnf "$f" "$db" "$h" "$n") || { echo "credenziali di $db non trovate in $f" >&2; exit 7; }
read -r E R K <<< "$(limiti "$O" "$db")"
[ "$R" = --skip-routines ] && echo "AVVISO $db: $K routine illeggibili con l'utente del sito, saltate: vanno salvate dal server del database" >&2
mysqldump --defaults-extra-file=<(echo "$O") --single-transaction --no-tablespaces $R --triggers $E --max_allowed_packet=512M --databases "$db" | gzip
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
# 2026-11-05 tipo dbremoto: i database su un'altra macchina li scarica quella del sito, con le sue credenziali

# NOTA
# parametri:
# $1    -> macchina da cui si fa il takeout, con l'utente davanti se non è root ( utente@host )
# $2    -> cartella del takeout preparata da va.takeout.inventory.sh
# $3... -> percorsi extra da salvare, p.es. /var/backups/vecchio-sito: finiscono in var.backups.vecchio-sito.tar.gz
#
# NOTA
# i nomi degli archivi sono il percorso con i punti al posto delle barre: etc.tar.gz, home.mario.tar.gz,
# var.www.sito.tar.gz, var.lib.mysql.DB.sql.gz, var.lib.mysql.users.UTENTE.sql.gz, remoto.HOST.DB.sql.gz
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
