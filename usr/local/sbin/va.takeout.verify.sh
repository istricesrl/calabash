#!/bin/bash

# UTILIZZO
# questo script verifica un takeout: per ogni archivio dell'elenco atteso.txt controlla che ci sia,
# che si legga per intero e che sia completo, poi confronta le impronte di SHA256SUMS; stampa OK o KO
# per ogni file ed esce con 1 se qualcosa non va

# verifico i parametri
if [ -n "$1" ]; then

    # log
    logger "$0 $1"

    DIR="${1%/}"
    if [ ! -f "$DIR/atteso.txt" ]; then
        echo "KO: manca $DIR/atteso.txt" >&2
        exit 2
    fi
    CLAUDE=$(sed -n 's/^claude=//p' "$DIR/meta.txt" 2>/dev/null)

    OK=0; KO=0
    ko() { echo "KO $1: $2"; KO=$(( KO + 1 )); }

    while IFS='|' read -r TIPO FILE SRC DIM; do

        F="$DIR/$FILE"
        if [ ! -s "$F" ]; then
            ko "$FILE" "manca"
            continue
        fi

        case "$TIPO" in
            tar|extra|tarlist)
                # leggere l'elenco decomprime tutto l'archivio, quindi controlla anche il gzip
                if [ "$FILE" = root.tar.gz ]; then
                    R=$(tar -tzf "$F" 2>/dev/null | awk '
                        $0=="root/takeout/installed.pkg.txt" {p=1}
                        $0=="root/takeout/sistema.md"       {s=1}
                        /^root\/takeout\/iptables\//         {i=1}
                        /^root\/\.claude\//                  {c=1}
                        END {print p+0, s+0, i+0, c+0}'; exit "${PIPESTATUS[0]}")
                    RC=$?
                    read -r P S I C <<< "$R"
                    if [ "$RC" -ne 0 ]; then ko "$FILE" "archivio illeggibile"; continue; fi
                    [ "$P$S$I" = 111 ] || { ko "$FILE" "mancano i file di /root/takeout/ ( pacchetti $P, sistema $S, iptables $I )"; continue; }
                    [ "$CLAUDE" = si ] && [ "$C" != 1 ] && { ko "$FILE" "manca /root/.claude"; continue; }
                else
                    tar -tzf "$F" > /dev/null 2>&1 || { ko "$FILE" "archivio illeggibile"; continue; }
                fi
                ;;
            db)
                CODA=$(gzip -dc "$F" 2>/dev/null | tail -c 300; exit "${PIPESTATUS[0]}") || { ko "$FILE" "gzip illeggibile"; continue; }
                grep -q -- '-- Dump completed' <<< "$CODA" || { ko "$FILE" "dump troncato, manca -- Dump completed"; continue; }
                ;;
            users)
                CODA=$(gzip -dc "$F" 2>/dev/null | tail -n 1; exit "${PIPESTATUS[0]}") || { ko "$FILE" "gzip illeggibile"; continue; }
                [ "$CODA" = "-- Grants completed" ] || { ko "$FILE" "elenco dei permessi troncato"; continue; }
                ;;
        esac

        echo "OK $FILE"
        OK=$(( OK + 1 ))

    done < "$DIR/atteso.txt"

    # impronte
    if [ -f "$DIR/SHA256SUMS" ]; then
        S=$( cd "$DIR" && sha256sum -c --quiet SHA256SUMS 2>&1 )
        if [ -z "$S" ]; then echo "OK SHA256SUMS"; else ko SHA256SUMS "$S"; fi
    else
        ko SHA256SUMS "manca"
    fi

    # archivi presenti ma non attesi: non sono un errore, ma vanno visti
    for F in "$DIR"/*.gz; do
        [ -f "$F" ] || continue
        grep -q "|$(basename "$F")|" "$DIR/atteso.txt" || echo "?? $(basename "$F") non è nell'elenco atteso"
    done

    echo "verificati: $OK OK, $KO KO"
    [ "$KO" -eq 0 ] || exit 1

else

    # sinossi
    echo "$0 CARTELLA"

fi

# uscita
exit 0

# REVISIONI
# 2026-10-22 prima versione, nata dal takeout di 35.195.31.8 ( Debian 10 su Google Cloud )

# NOTA
# parametri:
# $1 -> cartella del takeout preparata da va.takeout.inventory.sh e riempita da va.takeout.pull.sh
#
# NOTA
# cosa si controlla:
# tar        -> si legge l'elenco completo, che decomprime l'archivio e ne controlla il CRC
# root.tar.gz -> in più ci devono essere i file di /root/takeout/ e, se c'era, /root/.claude
# dump       -> si decomprime per intero e l'ultima riga deve essere -- Dump completed
# utenti     -> si decomprime per intero e l'ultima riga deve essere -- Grants completed
# SHA256SUMS -> le impronte calcolate da va.takeout.pull.sh devono corrispondere
#
# NOTA
# la verifica dice che gli archivi sono interi, non che bastano a ricreare la macchina: per un
# trasferimento la prova vera è il ripristino sulla macchina nuova, prima di spegnere la vecchia
