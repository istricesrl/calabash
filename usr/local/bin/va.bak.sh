#!/bin/bash

# UTILIZZO
# crea una copia di sicurezza di un file o di una cartella

# NOTA sulla convenzione dei nomi
# la copia NON prende il timestamp in coda al proprio nome: il timestamp diventa il nome
# della CARTELLA che la contiene, e il file conserva il suo nome e la sua estensione vera.
#
#     /var/backups/20260827123000-pre-tuning/etc/mysql/my.cnf     <- corretto
#     /etc/mysql/my.cnf.20260827123000                            <- come faceva prima
#
# il motivo non e' estetico: su Linux moltissimi meccanismi decidono cosa fare di un file
# guardandone l'estensione FINALE, e un timestamp appiccicato in fondo la nasconde. Casi
# reali incontrati su un nostro server:
#
#   /etc/cron.daily/         run-parts esegue i file: una copia di uno script di
#                            manutenzione li' dentro non e' stata eseguita solo perche'
#                            run-parts scarta i nomi che contengono punti
#   /etc/profile.d/          il glob e' *.sh: una copia di uno script non e' stata
#                            sourced da ogni shell solo per quello
#   regole ModSecurity       l'include e' rules/*.conf: una copia non e' stata caricata
#                            solo per quello, altrimenti avrebbe duplicato gli ID delle
#                            regole impedendo ad Apache di ripartire
#   document root Apache     il FilesMatch che nega .bak .conf .json .key .pem .sql e'
#                            ancorato a fine nome: pagina.php.bak.20260827 non fa match
#                            e viene servita in chiaro, cioe' sorgente pubblico
#
# in tutti questi casi il danno e' stato evitato dal caso, non dal criterio.

# parametri
SORGENTE="$1"
DESTINAZIONE="${2:-/var/backups}"
MOTIVO="$3"

# verifico i parametri
if [[ -n "$SORGENTE" ]]; then

    # verifico che la sorgente esista
    if [[ ! -e "$SORGENTE" ]]; then

	echo "$0: '$SORGENTE' non esiste" >&2
	logger "$0 fallito: '$SORGENTE' non esiste"
	exit 1

    fi

    # normalizzo la sorgente a percorso assoluto, cosi' la copia si porta dietro
    # la posizione di origine e due file omonimi non si sovrascrivono
    ASSOLUTO=$( readlink -f "$SORGENTE" )

    # comportamento storico, solo per compatibilita' di transizione: copia accanto
    # all'originale col timestamp in coda al nome (vedi NOTA in fondo)
    if [[ "${VA_BAK_LEGACY:-0}" = "1" ]]; then

	LEGACY="$2$ASSOLUTO.$( va.txt.timestamp.compressed.sh )"
	logger "$0 (legacy) $ASSOLUTO -> $LEGACY"

	if ! mkdir -p "$( dirname "$LEGACY" )" || ! cp -a "$ASSOLUTO" "$LEGACY"; then
	    echo "$0: copia di '$ASSOLUTO' fallita" >&2
	    logger "$0 (legacy) fallito: copia di '$ASSOLUTO' fallita"
	    exit 1
	fi

	echo "$LEGACY"
	exit 0

    fi

    # identificativo della copia: timestamp, piu' il motivo se e' stato indicato
    IDENTIFICATIVO=$( va.txt.timestamp.compressed.sh )
    if [[ -n "$MOTIVO" ]]; then
	IDENTIFICATIVO="$IDENTIFICATIVO-$( echo "$MOTIVO" | tr ' /' '--' )"
    fi

    # tolgo lo slash finale dalla destinazione, se c'e'
    DESTINAZIONE="${DESTINAZIONE%/}"

    # cartella di destinazione: <destinazione>/<identificativo>/<percorso di origine>
    CARTELLA="$DESTINAZIONE/$IDENTIFICATIVO$( dirname "$ASSOLUTO" )"

    # log
    logger "$0 $ASSOLUTO -> $CARTELLA"

    # creo la cartella: prima si faceva mkdir -p solo sulla destinazione base, quindi
    # con un secondo parametro la cp falliva sempre e il backup non veniva fatto
    if ! mkdir -p "$CARTELLA"; then

	echo "$0: impossibile creare '$CARTELLA'" >&2
	logger "$0 fallito: impossibile creare '$CARTELLA'"
	exit 1

    fi

    # copia: -a per conservare permessi, proprietario e date, che su un file di
    # configurazione servono tanto quanto il contenuto
    if ! cp -a "$ASSOLUTO" "$CARTELLA/"; then

	echo "$0: copia di '$ASSOLUTO' fallita" >&2
	logger "$0 fallito: copia di '$ASSOLUTO' fallita"
	exit 1

    fi

    # stampo la destinazione, cosi' chi chiama puo' catturarla
    echo "$CARTELLA/$( basename "$ASSOLUTO" )"

else

    # sinossi
    echo "$0 FILE|CARTELLA [/PATH/TO/BACKUP/] [MOTIVO]"

fi

# uscita
exit 0

# REVISIONI
# 2020-07-03 controllo funzionamento su Debian 10 (buster)
#            verificato che lo script possa essere lanciato in maniera sicura senza parametri
# 2026-08-27 la copia va in <destinazione>/<timestamp>[-motivo]/<percorso di origine>/ e
#            conserva il nome originale, invece di prendere il timestamp in coda al nome
#            e di finire accanto all'originale (vedi NOTA sulla convenzione dei nomi)
#            destinazione predefinita /var/backups invece della cartella dell'originale
#            corretto il caso con destinazione indicata: mkdir -p creava solo la base e
#            la cp falliva, quindi il backup non veniva eseguito (lo chiama cosi'
#            va.mysql.server.setup.sh, che quindi non ha mai prodotto una copia)
#            aggiunto cp -a, il controllo degli errori con uscita non nulla, e la stampa
#            del percorso di destinazione
#            gestite anche le cartelle, non piu' solo i file

# NOTA
# per il comportamento storico (copia accanto all'originale, timestamp in coda al nome)
# esportare VA_BAK_LEGACY=1 prima della chiamata; e' una compatibilita' di transizione,
# non usarla per nuovi script
