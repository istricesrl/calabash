#!/bin/bash

# UTILIZZO
# questo script fa il censimento di un singolo sito di cui si vuole fare il takeout, sia su CloudPanel
# ( /home/UTENTE/ ) sia su un server classico ( /var/www/SITO/ ): sulla macchina remota non scrive
# niente, e in locale scrive nella cartella del takeout la scheda del sito ( scheda.txt: righe di
# CloudPanel senza password e chiavi, utente di sistema ), l'inventario ( inventario.md ) e l'elenco dei
# file attesi ( atteso.txt ) che leggono va.takeout.pull.sh e va.takeout.verify.sh, gli stessi del
# takeout di una macchina intera

# verifico i parametri
if [ -n "$2" ] && [[ "$2" =~ ^[A-Za-z0-9._-]+$ ]]; then

    # log
    logger "$0 $1 $2 $3"

    # host remoto ( root se non specificato ), sito ( utente CloudPanel, dominio o cartella di /var/www ) e cartella del takeout
    HOST="$1"; [[ "$HOST" != *@* ]] && HOST="root@$HOST"
    SITO="$2"
    DIR="${3:-/var/backups/$SITO/$(date +%Y%m%d)-takeout}"
    SSH="ssh -o BatchMode=yes -o ConnectTimeout=10"

    # senza un accesso a chiave non si va avanti
    if ! $SSH -n "$HOST" true 2>/dev/null; then
        echo "KO: nessun accesso ssh a chiave verso $HOST" >&2
        exit 2
    fi

    # la cartella del takeout contiene chiavi e password
    umask 077
    mkdir -p "$DIR" && chmod 700 "$DIR" || exit 3

    # censimento remoto: le righe che cominciano per @ sono dati per questo script, il resto è markdown
    OUT=$($SSH "$HOST" "bash -s -- '$SITO'" <<'REMOTO'
export LC_ALL=C
S="$1"
CLP=/home/clp/htdocs/app/data/db.sq3
dim() { du -sb "$@" 2>/dev/null | awk '{s+=$1} END{printf "%d\n", s}'; }
umano() { numfmt --to=iec "${1:-0}" 2>/dev/null || echo "$1"; }
pieno() { [ -d "$1" ] && [ -n "$(find "$1" -mindepth 1 -maxdepth 1 2>/dev/null | head -1)" ]; }
att() { echo "@ATT $1|$2|$3|${4:-0}"; }
avviso() { echo "@AVVISO $*"; }
lista() { while read -r p; do [ -n "$p" ] && echo "@LIST $1 ${p#/}"; done; }
q() { sqlite3 -separator '|' "$CLP" "$1"; }
qh() { sqlite3 -header -separator '|' "$CLP" "$1"; }

# il sito: prima CloudPanel ( per utente o dominio ), poi /home e /var/www
ID=; U=; R=
if [ -f "$CLP" ] && command -v sqlite3 >/dev/null; then
    ID=$(q "select id from site where user='$S' or domain_name='$S'")
    [ -n "$ID" ] && U=$(q "select user from site where id=$ID") && R=/home/$U
fi
if [ -z "$R" ]; then
    for d in /home/$S /var/www/$S; do [ -d "$d" ] && { R=$d; break; }; done
fi
if [ -z "$R" ] || [ ! -d "$R" ]; then
    echo "@KO sito $S non trovato né in CloudPanel né in /home o /var/www"
    exit 0
fi
[ -z "$U" ] && U=$(stat -c %U "$R")

echo "## Sito"
echo
echo "- radice: \`$R\` ( $(umano "$(dim "$R")") ), utente \`$U\`"
[ -n "$ID" ] && echo "- CloudPanel: sito $ID, $(q "select domain_name || ', tipo ' || type || coalesce(', ' || application, '') || ', varnish ' || varnish_cache from site where id=$ID")"

# scheda del sito: le righe di CloudPanel senza le colonne con password e chiavi, scritta in locale
{
    echo "# utente"
    getent passwd "$U"; id "$U"
    if [ -n "$ID" ]; then
        echo; echo "# site"
        qh "select id, created_at, updated_at, type, domain_name, root_directory, user, application, varnish_cache, page_speed_enabled, allow_traffic_from_cloudflare_only, reverse_proxy_url, certificate_id, basic_auth_id from site where id=$ID"
        echo; echo "# vhost_template"
        q "select vhost_template from site where id=$ID"
        echo; echo "# php_settings"
        qh "select * from php_settings where site_id=$ID"
        echo; echo "# database"
        qh "select id, name, created_at from database where site_id=$ID"
        echo; echo "# database_user"
        qh "select u.id, u.user_name, u.permissions, d.name as db from database_user u join database d on d.id=u.database_id where d.site_id=$ID"
        echo; echo "# certificate"
        qh "select id, uid, type, default_certificate, created_at, expires_at from certificate where site_id=$ID"
        echo; echo "# cron_job"
        qh "select * from cron_job where site_id=$ID"
        echo; echo "# ssh_user"
        qh "select id, user_name, created_at from ssh_user where site_id=$ID"
        echo; echo "# ftp_user"
        qh "select id, user_name, home_directory, created_at from ftp_user where site_id=$ID"
        echo; echo "# basic_auth"
        qh "select b.id, b.is_active, b.user_name, b.whitelisted_ips from basic_auth b join site s on s.basic_auth_id=b.id where s.id=$ID"
    fi
} 2>&1 | sed 's/^/@SCHEDA /'

# i file del sito: le copie di backup di CloudPanel restano fuori, si aggiungono come extra se servono
N=$(echo "${R#/}" | tr / .)
F=$(find "$R" -mindepth 1 -maxdepth 1 ! -name backups)
att tarlist "$N.tar.gz" "$N.list" "$(echo "$F" | xargs -r -d '\n' du -cb 2>/dev/null | tail -1 | cut -f1)"
echo "$F" | lista "$N.list"
if pieno "$R/backups"; then
    echo "- \`$R/backups\` ( $(umano "$(dim "$R/backups")") ) escluso: per salvarlo va passato a va.takeout.pull.sh come extra \`${R#/}/backups\`"
    avviso "copie di backup in $R/backups ( $(umano "$(dim "$R/backups")") ) escluse dal takeout"
fi

# configurazione: vhost, pool PHP, certificati, logrotate, cron
RE="$R(/|;|\"|'|[[:space:]]|$)"
V=$(grep -l -s -E "$RE" /etc/nginx/sites-enabled/* /etc/apache2/sites-enabled/*)
DOM=$( { [ -n "$ID" ] && q "select domain_name from site where id=$ID"
         [ -n "$V" ] && grep -h -s -E '^\s*server_name\s' $V | sed 's/server_name//; s/;//' | tr ' ' '\n'
         [ -n "$V" ] && grep -h -s -i -E '^\s*(ServerName|ServerAlias)\s' $V | awk '{for(i=2;i<=NF;i++)print $i}'
       } | tr -d '\r' | sed 's/:.*//' | grep '\.' | grep -v -E '^\*|^_|localhost|^[0-9.]+$' | sort -u)
C=$( {
    for v in $V; do echo "$v"; readlink -f "$v"; done
    if [ "$U" != www-data ] && [ "$U" != root ]; then
        grep -l -s -E "^\s*user\s*=\s*$U\s*$" /etc/php/*/fpm/pool.d/*.conf
        ls -d /var/spool/cron/crontabs/$U 2>/dev/null
    fi
    grep -l -s -E "$RE" /etc/php/*/fpm/pool.d/*.conf /etc/logrotate.d/* /etc/cron.d/* /etc/varnish/*
    grep -l -s -E "^\s*$U\s*$|/$U\s*\{" /etc/logrotate.d/*
    for d in $DOM; do
        ls -d /etc/nginx/ssl-certificates/$d.crt /etc/nginx/ssl-certificates/$d.key \
              /etc/letsencrypt/live/$d /etc/letsencrypt/archive/$d /etc/letsencrypt/renewal/$d.conf 2>/dev/null
    done
} | sort -u)
att tarlist "sito.$S.config.tar.gz" "sito.$S.config.list" "$(echo "$C" | xargs -r -d '\n' du -cb 2>/dev/null | tail -1 | cut -f1)"
echo "$C" | lista "sito.$S.config.list"
echo
echo "## Configurazione"
echo
echo "$C" | sed 's/^/- `/; s/$/`/'
[ -z "$V" ] && avviso "nessun vhost nginx o apache punta a $R"
[ -n "$ID" ] && [ "$(q "select count(*) from cron_job where site_id=$ID")" != 0 ] && echo "- cron di CloudPanel: $(q "select count(*) from cron_job where site_id=$ID") ( in scheda.txt )"

# database: da CloudPanel, oppure dai file di configurazione dell'applicazione
DBS=; DBU=; REMOTI=
locale() { case "$1" in ''|localhost|localhost:*|127.0.0.1|127.0.0.1:*|::1) return 0 ;; esac; return 1; }
if [ -n "$ID" ]; then
    DBS=$(q "select name from database where site_id=$ID")
    DBU=$(q "select u.user_name from database_user u join database d on d.id=u.database_id where d.site_id=$ID")
fi
CF=$(find "$R" -maxdepth 5 \( -name wp-config.php -o -name .env \) -not -path '*/backups/*' -not -path '*/node_modules/*' -not -path '*/vendor/*' 2>/dev/null)
for f in $CF; do
    k() { sed -n -E "s/.*define *\( *['\"]$1['\"] *, *['\"]([^'\"]*)['\"].*/\1/p; s/^$2=[\"']?([^\"' ]*).*/\1/p" "$f"; }
    h=$(k DB_HOST DB_HOST | head -1)
    if locale "$h"; then
        DBS="$DBS"$'\n'"$(k DB_NAME DB_DATABASE)"
        DBU="$DBU"$'\n'"$(k DB_USER DB_USERNAME)"
    else
        REMOTI="$REMOTI"$'\n'"$(k DB_NAME DB_DATABASE)|$h|$(k DB_USER DB_USERNAME)|$f"
    fi
done
# i deploy glisweb ( dev/, test/, stable/ ): i server MySQL stanno in src/config.json, sotto mysql.servers
for f in $(find "$R" -maxdepth 4 -path '*/src/config.json' -not -path '*/backups/*' 2>/dev/null); do
    if command -v python3 >/dev/null; then
        L=$(python3 -c '
import json, sys
for s in json.load(open(sys.argv[1])).get("mysql", {}).get("servers", {}).values():
    if isinstance(s, dict) and s.get("db"):
        print("%s|%s|%s" % (s["db"], s.get("address", ""), s.get("username", "")))
' "$f" 2>/dev/null)
    elif command -v jq >/dev/null; then
        L=$(jq -r '.mysql.servers // {} | .[] | select(.db) | "\(.db)|\(.address // "")|\(.username // "")"' "$f" 2>/dev/null)
    else
        avviso "$f: né python3 né jq per leggerlo, i database del deploy vanno cercati a mano"; continue
    fi
    while IFS='|' read -r db h u; do
        [ -z "$db" ] && continue
        if locale "$h"; then DBS="$DBS"$'\n'"$db"; DBU="$DBU"$'\n'"$u"
        else REMOTI="$REMOTI"$'\n'"$db|$h|$u|$f"
        fi
    done <<< "$L"
done
DBS=$(echo "$DBS" | grep . | sort -u); DBU=$(echo "$DBU" | grep . | sort -u); REMOTI=$(echo "$REMOTI" | grep . | sort -u)
echo
echo "## Database"
echo
# un database su un'altra macchina non lo salva va.takeout.pull.sh: si dice dove sta e lo si salva da lì
for h in $(echo "$REMOTI" | cut -d'|' -f2 | grep . | sort -u); do
    avviso "database su $h, non su questa macchina: $(echo "$REMOTI" | awk -F'|' -v h="$h" '$2==h{print $1}' | sort -u | tr '\n' ' ')- vanno salvati a mano da lì"
done
echo "$REMOTI" | grep . | while IFS='|' read -r db h u f; do echo "- database \`$db\` su **$h** ( utente \`$u\`, da \`$f\` ): non è su questa macchina"; done
if [ -z "$DBS" ] && [ -n "$REMOTI" ]; then
    echo "@MYSQL -"
elif [ -z "$DBS" ]; then
    echo "- nessun database trovato ( né in CloudPanel né in wp-config.php, .env o src/config.json )"
    avviso "nessun database trovato per $S: se il sito ne usa uno, va aggiunto a mano"
    echo "@MYSQL -"
elif command -v mysql >/dev/null && pgrep -x 'mysqld|mariadbd' >/dev/null; then
    MY=-
    if [ -f /etc/mysql.conf ] && mysql --defaults-extra-file=/etc/mysql.conf -N -e 'select 1' >/dev/null 2>&1; then MY=--defaults-extra-file=/etc/mysql.conf
    elif mysql -N -e 'select 1' >/dev/null 2>&1; then MY=-
    elif [ -f /etc/mysql/debian.cnf ] && mysql --defaults-file=/etc/mysql/debian.cnf -N -e 'select 1' >/dev/null 2>&1; then MY=--defaults-file=/etc/mysql/debian.cnf
    else MY=KO; avviso "MySQL attivo ma non riesco a collegarmi: i database vanno salvati a mano"
    fi
    echo "@MYSQL $MY"
    if [ "$MY" != KO ]; then
        O=$MY; [ "$O" = - ] && O=
        echo "- server: $(mysql $O -N -e 'select version()')"
        for db in $DBS; do
            if [ -z "$(mysql $O -N -B -e "select schema_name from information_schema.schemata where schema_name='$db'")" ]; then
                echo "- database \`$db\`: **non esiste sul server**"; avviso "il database $db citato dal sito non esiste sul server"
                continue
            fi
            d=$(mysql $O -N -B -e "select coalesce(sum(data_length+index_length),0) from information_schema.tables where table_schema='$db'")
            att db "var.lib.mysql.$db.sql.gz" "$db" "$d"
            echo "- database \`$db\`: $(umano "$d")"
            DBU="$DBU"$'\n'"$(mysql $O -N -B -e "select distinct User from mysql.db where Db='$db' or '$db' like Db")"
        done
        for u in $(echo "$DBU" | grep . | sort -u); do
            [ -z "$(mysql $O -N -B -e "select 1 from mysql.user where User='$u' limit 1")" ] && continue
            att users "var.lib.mysql.users.$(echo "$u" | tr -c 'A-Za-z0-9._\n-' '_').sql.gz" "$u" 0
            echo "- utente \`$u\`: $(mysql $O -N -B -e "select group_concat(distinct Db) from mysql.db where User='$u'")"
        done
    fi
else
    echo "- **MySQL non è attivo**: i database \`$(echo $DBS)\` non si possono salvare"
    avviso "MySQL non è attivo: avviarlo prima di va.takeout.pull.sh, altrimenti i database $(echo $DBS) non si salvano"
    echo "@MYSQL KO"
fi

for d in $DOM; do echo "@DNS $d"; done
# gli indirizzi di questa macchina: quelli delle interfacce e, dietro una NAT ( GCP, AWS ), quello pubblico
for i in $(hostname -I 2>/dev/null); do echo "@IP $i"; done
P=$(curl -s -m 3 -H 'Metadata-Flavor: Google' http://169.254.169.254/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip 2>/dev/null)
[[ "$P" =~ ^[0-9.]+$ ]] || P=$(curl -s -m 3 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)
[[ "$P" =~ ^[0-9.]+$ ]] || P=$(curl -s -m 3 https://api.ipify.org 2>/dev/null)
[[ "$P" =~ ^[0-9.]+$ ]] && echo "@IP $P"
echo "@FINE"
REMOTO
    ) || { echo "KO: il censimento remoto non è andato a buon fine" >&2; exit 4; }
    if grep -q '^@KO ' <<< "$OUT"; then sed -n 's/^@KO /KO: /p' <<< "$OUT" >&2; exit 4; fi
    grep -q '^@FINE' <<< "$OUT" || { echo "KO: censimento remoto interrotto" >&2; exit 4; }

    # dati per gli altri script
    grep '^@ATT ' <<< "$OUT" | cut -c6- > "$DIR/atteso.txt"
    rm -f "$DIR"/*.list
    awk -v d="$DIR" '/^@LIST /{f=$2; sub(/^@LIST [^ ]+ /, ""); print > (d"/"f)}' <<< "$OUT"
    MY=$(sed -n 's/^@MYSQL //p' <<< "$OUT")
    sed -n 's/^@SCHEDA //p' <<< "$OUT" > "$DIR/scheda.txt"
    {
        echo "host=$HOST"
        echo "nome=$SITO"
        echo "data=$(date '+%Y-%m-%d %H:%M')"
        echo "mysql=$MY"
        echo "claude=no"
    } > "$DIR/meta.txt"
    AVVISI=$(sed -n 's/^@AVVISO //p' <<< "$OUT")

    # spazio: si confronta il totale non compresso con quello libero qui
    TOT=$(awk -F'|' '{s+=$4} END{printf "%d\n", s}' "$DIR/atteso.txt")
    LIB=$(df -B1 --output=avail "$DIR" | tail -1 | tr -d ' ')
    if [ "$LIB" -ge "$TOT" ]; then SPAZIO=OK
    elif [ "$LIB" -ge $(( TOT * 4 / 10 )) ]; then SPAZIO="ATTENZIONE ( basta solo se la compressione rende più del $(( 100 - LIB * 100 / TOT ))% )"
    else SPAZIO=KO; AVVISI="$AVVISI"$'\n'"spazio insufficiente in $DIR: lo deve liberare il sistemista"
    fi

    # nomi DNS: puntano ancora a questa macchina?
    # l'host com'è stato scritto ( anche 127.0.0.1 ) più gli indirizzi che la macchina dichiara di avere
    IP=" $(getent ahostsv4 "${HOST#*@}" | awk 'NR==1{print $1}') $(sed -n 's/^@IP //p' <<< "$OUT" | tr '\n' ' ')"
    DNS=$(sed -n 's/^@DNS //p' <<< "$OUT" | while read -r n; do
        r=$(getent ahostsv4 "$n" | awk '{print $1}' | sort -u | tr '\n' ' ')
        if [ -z "$r" ]; then echo "- \`$n\`: non risolve"
        elif [ -n "$(for a in $r; do [[ "$IP" == *" $a "* ]] && echo s; done)" ]; then echo "- \`$n\`: **punta qui** ( $r)"
        else echo "- \`$n\`: punta altrove ( $r)"
        fi
    done)

    # inventario
    {
        echo "# Takeout del sito $SITO"
        echo
        echo "censimento su \`$HOST\` del $(date '+%d/%m/%Y %H:%M'), cartella \`$DIR\`"
        echo
        echo "## Avvisi"
        echo
        if [ -n "$(echo "$AVVISI" | grep .)" ]; then echo "$AVVISI" | grep . | sed 's/^/- /'; else echo "- nessuno"; fi
        echo
        echo "## Spazio"
        echo
        echo "- da salvare ( non compresso ): $(numfmt --to=iec "$TOT")"
        echo "- libero in \`$DIR\`: $(numfmt --to=iec "$LIB")"
        echo "- esito: $SPAZIO"
        echo
        grep -v '^@' <<< "$OUT"
        echo
        echo "## Nomi DNS"
        echo
        echo "${DNS:-- nessuno trovato}"
        echo
        echo "## File attesi"
        echo
        echo "| file | tipo | da salvare |"
        echo "|---|---|---|"
        while IFS='|' read -r t f s d; do echo "| \`$f\` | $t | $(numfmt --to=iec "${d:-0}") |"; done < "$DIR/atteso.txt"
    } > "$DIR/inventario.md"
    chmod 600 "$DIR"/*

    # a video solo il riassunto
    echo "inventario: $DIR/inventario.md"
    echo "archivi attesi: $(wc -l < "$DIR/atteso.txt") ( $(cut -d'|' -f1 "$DIR/atteso.txt" | sort | uniq -c | awk '{printf "%s %s ", $1, $2}'))"
    echo "da salvare: $(numfmt --to=iec "$TOT"), libero: $(numfmt --to=iec "$LIB"), spazio: $SPAZIO"
    echo "nomi DNS che puntano qui: $(grep -c 'punta qui' <<< "$DNS")"
    echo "$AVVISI" | grep . | sed 's/^/AVVISO: /'

    # con lo spazio insufficiente o i database irraggiungibili non si prosegue
    [ "$SPAZIO" = KO ] && exit 1
    [ "$MY" = KO ] && exit 1

else

    # sinossi
    echo "$0 HOST SITO [CARTELLA]"

fi

# uscita
exit 0

# REVISIONI
# 2026-10-22 prima versione, nata dal takeout di www.pcstop.eu su CloudPanel
# 2026-11-05 la scheda si scrive nella cartella del takeout ( sulla macchina remota non si scrive più niente ),
#            database dei deploy glisweb da src/config.json, database remoti segnalati e non dati per
#            mancanti, nomi DNS confrontati anche con gli indirizzi dichiarati dalla macchina ( HOST 127.0.0.1 )

# NOTA
# parametri:
# $1 -> macchina che ospita il sito, ip o nome, con l'utente davanti se non è root ( utente@host )
# $2 -> il sito: utente o dominio di CloudPanel ( /home/UTENTE ), oppure nome della cartella in /var/www
# $3 -> cartella del takeout opzionale, di default /var/backups/SITO/AAAAMMGG-takeout
#
# NOTA
# lo script gira sulla macchina che riceve il takeout e lavora via ssh: sulla macchina del sito non
# scrive niente; il resto della procedura è va.takeout.pull.sh e va.takeout.verify.sh,
# e le copie di backup di CloudPanel ( /home/UTENTE/backups ) si salvano solo passandole a pull come extra
#
# NOTA
# file prodotti nella cartella del takeout:
# inventario.md          -> il censimento da leggere prima di salvare
# atteso.txt             -> una riga per archivio: tipo|file|sorgente|byte non compressi
# meta.txt               -> host, sito, data, credenziali MySQL da usare
# scheda.txt             -> utente di sistema e righe di CloudPanel del sito, senza password e chiavi
# *.list                 -> i percorsi dei file del sito e della sua configurazione, letti da pull
#
# NOTA
# negli archivi: i file del sito ( home.UTENTE.tar.gz o var.www.SITO.tar.gz ), la configurazione
# ( sito.SITO.config.tar.gz: vhost, pool PHP-FPM, certificati, logrotate, crontab ),
# un dump per database e uno per utente MySQL con i suoi grant
