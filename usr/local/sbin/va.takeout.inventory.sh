#!/bin/bash

# UTILIZZO
# questo script fa il censimento di una macchina di cui si vuole fare il takeout, prima di salvarne
# qualsiasi cosa: sulla macchina remota prepara in /root/takeout/ l'elenco dei pacchetti, le regole
# del firewall e la scheda del sistema ( finiscono poi in root.tar.gz ), e in locale scrive nella
# cartella del takeout l'inventario ( inventario.md ) e l'elenco dei file attesi ( atteso.txt ) che
# leggono va.takeout.pull.sh e va.takeout.verify.sh

# verifico i parametri
if [ -n "$2" ]; then

    # log
    logger "$0 $1 $2 $3"

    # host remoto ( root se non specificato ), nome della macchina e cartella del takeout
    HOST="$1"; [[ "$HOST" != *@* ]] && HOST="root@$HOST"
    NOME="$2"
    DIR="${3:-/var/backups/$NOME/$(date +%Y%m%d)-takeout}"
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
    OUT=$($SSH "$HOST" 'bash -s' <<'REMOTO'
export LC_ALL=C
T=/root/takeout
dim() { du -sb "$1" 2>/dev/null | cut -f1; }
umano() { numfmt --to=iec "${1:-0}" 2>/dev/null || echo "$1"; }
pieno() { [ -d "$1" ] && [ -n "$(find "$1" -mindepth 1 -maxdepth 1 2>/dev/null | head -1)" ]; }
att() { echo "@ATT $1|$2|$3|${4:-0}"; }
avviso() { echo "@AVVISO $*"; }

# file di servizio dentro /root/takeout, così finiscono in root.tar.gz
mkdir -p $T/iptables && chmod 700 $T
dpkg --get-selections > $T/installed.pkg.txt 2>/dev/null
command -v iptables-save >/dev/null && iptables-save > $T/iptables/rules.v4 2>/dev/null
command -v ip6tables-save >/dev/null && ip6tables-save > $T/iptables/rules.v6 2>/dev/null
command -v nft >/dev/null && nft list ruleset > $T/iptables/nft.ruleset 2>/dev/null

# scheda del sistema
{
    sez() { echo; echo "## $1"; echo; echo '```'; }
    fine() { echo '```'; }
    echo "# Sistema di $(hostname -f 2>/dev/null || hostname)"
    echo; echo "scheda generata da va.takeout.inventory.sh il $(date '+%d/%m/%Y %H:%M')"
    sez "versione"; cat /etc/os-release; echo "debian_version: $(cat /etc/debian_version 2>/dev/null)"; uname -a; fine
    sez "cpu e memoria"; echo "cpu: $(nproc)"; free -h; swapon --show 2>/dev/null; fine
    sez "dischi"; lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,UUID 2>/dev/null || lsblk; fine
    sez "filesystem"; df -hT -x tmpfs -x devtmpfs; fine
    sez "mount"; findmnt -l -o TARGET,SOURCE,FSTYPE,OPTIONS | grep -v -E ' (proc|sysfs|cgroup2?|devpts|tmpfs|devtmpfs|securityfs|pstore|debugfs|mqueue|hugetlbfs|configfs|fusectl|bpf|tracefs|autofs|binfmt_misc|efivarfs|rpc_pipefs|nsfs) '; fine
    sez "fstab"; grep -v '^\s*#' /etc/fstab | grep -v '^\s*$'; fine
    sez "rete"; ip -br addr; echo; ip route; echo; grep -v '^#' /etc/resolv.conf; fine
    sez "porte in ascolto"; ss -tlnpu; fine
    sez "servizi abilitati"; systemctl list-unit-files --type=service --state=enabled --no-legend; fine
    sez "servizi attivi"; systemctl list-units --type=service --state=running --no-legend; fine
    sez "timer"; systemctl list-timers --all --no-legend; fine
    sez "ora"; timedatectl 2>/dev/null | head -5; fine
} > $T/sistema.md 2>/dev/null
chmod -R go-rwx $T

echo "## Sistema"
echo
echo "- macchina: \`$(hostname -f 2>/dev/null || hostname)\`, $(. /etc/os-release; echo "$PRETTY_NAME") ( debian $(cat /etc/debian_version 2>/dev/null) ), kernel $(uname -r)"
echo "- disco: $(df -h / | awk 'NR==2{print $3" usati su "$2}')"
echo "- preparati in \`/root/takeout/\`: \`installed.pkg.txt\` ( $(wc -l < $T/installed.pkg.txt) pacchetti ), \`iptables/\`, \`sistema.md\`"

# cloud: chi ospita la macchina decide cosa fare dopo ( snapshot, dischi, IP statici )
G() { curl -s -m 3 -H 'Metadata-Flavor: Google' "http://metadata.google.internal/computeMetadata/v1/$1" 2>/dev/null || wget -q -T 3 -O - --header='Metadata-Flavor: Google' "http://metadata.google.internal/computeMetadata/v1/$1" 2>/dev/null; }
GN=$(G instance/name)
if [ -n "$GN" ]; then
    GZ=$(G instance/zone); GZ=${GZ##*/}
    echo "@GCP $GN|$GZ|$(G project/project-id)"
fi

# archivi fissi
echo
echo "## Cartelle"
echo
for p in etc root usr/local/bin usr/local/sbin opt srv var/spool/cron/crontabs var/mail var/vmail; do
    [ "$p" = etc ] || [ "$p" = root ] || pieno "/$p" || continue
    d=$(dim "/$p"); att tar "$(echo "$p" | tr / .).tar.gz" "$p" "$d"
    echo "- \`/$p\`: $(umano "$d")"
done
for h in /home/*/; do
    [ -d "$h" ] || continue
    u=$(basename "$h"); d=$(dim "$h"); att tar "home.$u.tar.gz" "home/$u" "$d"
    echo "- \`/home/$u\`: $(umano "$d")"
done
awk -F: '$3>=1000 && $3<65534 && $6!~/^\/home\// {print "- utente `"$1"` con la home fuori da /home: `"$6"`"}' /etc/passwd
awk -F: '$3>=1000 && $3<65534 && $6!~/^\/home\// {print "@AVVISO utente "$1" con la home in "$6": controllare che sia coperta"}' /etc/passwd

# l'esperienza di Claude sta in /root/.claude: la verifica controlla che sia in root.tar.gz
if [ -d /root/.claude ]; then
    echo "@CLAUDE si"
    echo "- Claude: \`/root/.claude\` $(umano "$(dim /root/.claude)"), $(ls /root/.claude/skills 2>/dev/null | wc -l) skill, $(find /root/.claude/projects -path '*/memory/*.md' 2>/dev/null | wc -l) memorie$( [ -f /root/CLAUDE.md ] && echo ", \`/root/CLAUDE.md\`" )"
fi
[ -f /root/READ.md ] && echo "- \`/root/READ.md\` presente: si legge prima di decidere il dopo"

# siti
echo
echo "## Siti in /var/www"
echo
for s in /var/www/*/; do
    [ -d "$s" ] || continue
    n=$(basename "$s"); d=$(dim "$s"); att tar "var.www.$n.tar.gz" "var/www/$n" "$d"
    echo "- \`$n\`: $(umano "$d")"
done
find /var/www -mindepth 1 -maxdepth 1 ! -type d 2>/dev/null | while read -r f; do
    echo "- file sciolto \`$f\`"; avviso "file sciolto in /var/www: $f ( va aggiunto come extra )"
done

# eseguibili che nessun pacchetto dichiara nelle cartelle di sistema
echo
echo "## Eseguibili fuori dai pacchetti"
echo
P=$(mktemp)
# con usrmerge dpkg registra /bin/bash ma il file sta in /usr/bin/bash: valgono tutti e due
cat /var/lib/dpkg/info/*.list 2>/dev/null | awk '{print} /^\/(bin|sbin|lib)\//{print "/usr"$0}' | sort -u > "$P"
for b in bin sbin usr/bin usr/sbin; do
    [ -L "/$b" ] && continue
    L=$(find "/$b" -maxdepth 1 \( -type f -o -type l \) 2>/dev/null | sort | comm -23 - "$P" | while read -r f; do
        [ -L "$f" ] && case "$(readlink "$f")" in /etc/alternatives/*) continue ;; esac
        echo "$f"
    done)
    [ -n "$L" ] || continue
    nome="$(echo "$b" | tr / .).custom"
    echo "$L" | while read -r f; do echo "@LIST $nome.list ${f#/}"; done
    att tarlist "$nome.tar.gz" "$nome.list" "$(echo "$L" | xargs -d '\n' du -cb 2>/dev/null | tail -1 | cut -f1)"
    echo "- \`/$b\`: $(echo "$L" | wc -l) file ( $(echo "$L" | head -5 | xargs -n1 basename | tr '\n' ' ')$( [ "$(echo "$L" | wc -l)" -gt 5 ] && echo '…' ) )"
done

# cron: cosa gira e se gli script che lancia finiscono in qualche archivio
echo
echo "## Cron"
echo
F=$(ls /etc/crontab /etc/cron.d/* /var/spool/cron/crontabs/* 2>/dev/null)
for f in $F; do
    r=$(grep -v '^\s*#' "$f" | grep -v '^\s*$' | grep -v '^[A-Z_]*=' )
    [ -n "$r" ] || continue
    echo "### \`$f\`"; echo; echo '```'; echo "$r"; echo '```'; echo
done
for c in /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly; do
    for f in "$c"/*; do
        [ -f "$f" ] || continue
        grep -qxF "$f" "$P" || echo "- \`$f\` non viene da un pacchetto"
    done
done
echo
for f in $F /etc/cron.hourly/* /etc/cron.daily/* /etc/cron.weekly/* /etc/cron.monthly/*; do
    [ -f "$f" ] && grep -v '^\s*#' "$f" | grep -o "/[^ ;|&>\"'\`()]*"
done | sort -u | while read -r x; do
    # solo gli eseguibili: nelle righe di cron compaiono anche log e file di /proc
    [ -f "$x" ] && [ -x "$x" ] || continue
    case "$x" in /proc/*|/sys/*|/dev/*) continue ;; esac
    grep -qxF "$x" "$P" && continue
    case "$x" in
        /etc/*|/root/*|/home/*|/usr/local/*|/opt/*|/srv/*|/var/www/*|/bin/*|/sbin/*|/usr/bin/*|/usr/sbin/*|/var/spool/cron/*) echo "- script dei cron \`$x\`: coperto" ;;
        *) echo "- script dei cron \`$x\`: **NON COPERTO**"; avviso "script lanciato dai cron e non coperto: $x" ;;
    esac
done
rm -f "$P"

# /var/backups: oltre ai file standard di Debian, c'è qualcosa da salvare?
echo
echo "## /var/backups"
echo
B=$(find /var/backups -mindepth 1 -maxdepth 2 2>/dev/null | grep -v -E '/(alternatives(\.tar)?|apt\.extended_states|dpkg\.(status|diversions|statoverride|arch)|passwd|group|shadow|gshadow|infodir|aptitude\.pkgstates)(\.bak|\.[0-9]+(\.gz)?)?$' | sort)
if [ -n "$B" ]; then
    echo "$B" | while read -r f; do echo "- \`$f\` $(umano "$(dim "$f")") ( $(date -r "$f" +%d/%m/%Y) )"; done
    avviso "/var/backups contiene $(echo "$B" | wc -l) voci non standard: decidere se salvarle come extra"
else
    echo "- solo i file standard di Debian"
fi

# database
echo
echo "## Database"
echo
if command -v mysql >/dev/null && pgrep -x 'mysqld|mariadbd' >/dev/null; then
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
        mysql $O -N -B -e "select s.schema_name, coalesce(sum(t.data_length+t.index_length),0) from information_schema.schemata s left join information_schema.tables t on t.table_schema=s.schema_name where s.schema_name not in ('information_schema','performance_schema','sys','mysql') group by s.schema_name" | while read -r db d; do
            att db "var.lib.mysql.$db.sql.gz" "$db" "$d"
            echo "- database \`$db\`: $(umano "$d")"
        done
        mysql $O -N -B -e "select distinct User from mysql.user where User<>'' and User not in ('mariadb.sys','mysql.sys','mysql.session','mysql.infoschema')" | while read -r u; do
            att users "var.lib.mysql.users.$(echo "$u" | tr -c 'A-Za-z0-9._\n-' '_').sql.gz" "$u" 0
            echo "- utente \`$u\`"
        done
    fi
else
    echo "- nessun MySQL/MariaDB attivo"
fi
pgrep -x postgres >/dev/null && { echo "- **PostgreSQL attivo**: non gestito da questi script"; avviso "PostgreSQL attivo: salvarlo a mano con pg_dumpall"; }
[ -d /var/lib/docker ] && { echo "- **Docker** presente ( $(umano "$(dim /var/lib/docker)") )"; avviso "Docker presente: volumi e immagini non sono coperti"; }
pgrep -x mongod >/dev/null && avviso "mongod attivo: non coperto da questi script"
if pieno /var/lib/redis; then
    d=$(dim /var/lib/redis); att tar var.lib.redis.tar.gz var/lib/redis "$d"
    echo "- redis: \`/var/lib/redis\` $(umano "$d")"
fi

# nomi DNS che la macchina serve: si risolvono in locale
for n in $(hostname -f 2>/dev/null) \
         $(grep -h -i -E '^\s*(ServerName|ServerAlias)\s' /etc/apache2/sites-enabled/* 2>/dev/null | awk '{for(i=2;i<=NF;i++)print $i}') \
         $(grep -h -E '^\s*server_name\s' /etc/nginx/sites-enabled/* 2>/dev/null | sed 's/server_name//; s/;//') \
         $(ls /etc/letsencrypt/live 2>/dev/null | grep -v README); do
    echo "$n"
done | tr -d '\r' | sed 's/:.*//' | grep '\.' | grep -v -E '^\*|^_|localhost|^[0-9.]+$' | sort -u | sed 's/^/@DNS /'

echo "@FINE"
REMOTO
    ) || { echo "KO: il censimento remoto non è andato a buon fine" >&2; exit 4; }
    grep -q '^@FINE' <<< "$OUT" || { echo "KO: censimento remoto interrotto" >&2; exit 4; }

    # dati per gli altri script
    grep '^@ATT ' <<< "$OUT" | cut -c6- > "$DIR/atteso.txt"
    rm -f "$DIR"/*.custom.list
    awk -v d="$DIR" '/^@LIST /{print $3 > (d"/"$2)}' <<< "$OUT"
    {
        echo "host=$HOST"
        echo "nome=$NOME"
        echo "data=$(date '+%Y-%m-%d %H:%M')"
        echo "mysql=$(sed -n 's/^@MYSQL //p' <<< "$OUT")"
        echo "claude=$(sed -n 's/^@CLAUDE //p' <<< "$OUT")"
    } > "$DIR/meta.txt"
    AVVISI=$(sed -n 's/^@AVVISO //p' <<< "$OUT")

    # spazio: si confronta il totale non compresso con quello libero qui
    TOT=$(awk -F'|' '{s+=$4} END{print s+0}' "$DIR/atteso.txt")
    LIB=$(df -B1 --output=avail "$DIR" | tail -1 | tr -d ' ')
    if [ "$LIB" -ge "$TOT" ]; then SPAZIO=OK
    elif [ "$LIB" -ge $(( TOT * 4 / 10 )) ]; then SPAZIO="ATTENZIONE ( basta solo se la compressione rende più del $(( 100 - LIB * 100 / TOT ))% )"
    else SPAZIO=KO; AVVISI="$AVVISI"$'\n'"spazio insufficiente in $DIR: lo deve liberare il sistemista"
    fi

    # nomi DNS: puntano ancora a questa macchina?
    IP=$(getent ahostsv4 "${HOST#*@}" | awk 'NR==1{print $1}')
    DNS=$(sed -n 's/^@DNS //p' <<< "$OUT" | while read -r n; do
        r=$(getent ahostsv4 "$n" | awk '{print $1}' | sort -u | tr '\n' ' ')
        if [ -z "$r" ]; then echo "- \`$n\`: non risolve"
        elif [[ " $r" == *" $IP "* ]]; then echo "- \`$n\`: **punta qui** ( $r)"
        else echo "- \`$n\`: punta altrove ( $r)"
        fi
    done)

    # inventario
    {
        echo "# Takeout di $NOME"
        echo
        echo "censimento di \`$HOST\` del $(date '+%d/%m/%Y %H:%M'), cartella \`$DIR\`"
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
        G=$(sed -n 's/^@GCP //p' <<< "$OUT")
        if [ -n "$G" ]; then
            IFS='|' read -r GN GZ GP <<< "$G"
            echo
            echo "## Google Cloud"
            echo
            echo "- istanza \`$GN\`, zona \`$GZ\`, progetto \`$GP\`"
            echo "- dischi: \`gcloud compute instances describe $GN --zone $GZ --project $GP --format='value(disks[].source)'\`"
            echo "- snapshot: \`gcloud compute snapshots list --project $GP --filter='sourceDisk~$GZ'\`"
        fi
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

    # con lo spazio insufficiente non si prosegue
    [ "$SPAZIO" = KO ] && exit 1

else

    # sinossi
    echo "$0 HOST NOME [CARTELLA]"

fi

# uscita
exit 0

# REVISIONI
# 2026-10-22 prima versione, nata dal takeout di 35.195.31.8 ( Debian 10 su Google Cloud )

# NOTA
# parametri:
# $1 -> macchina da censire, ip o nome, con l'utente davanti se non è root ( utente@host )
# $2 -> nome della macchina, dà il nome alla cartella /var/backups/NOME/
# $3 -> cartella del takeout opzionale, di default /var/backups/NOME/AAAAMMGG-takeout
#
# NOTA
# lo script gira sulla macchina che riceve il takeout e lavora via ssh: sulla macchina censita scrive
# soltanto in /root/takeout/; il resto della procedura è va.takeout.pull.sh e va.takeout.verify.sh
#
# NOTA
# file prodotti nella cartella del takeout:
# inventario.md    -> il censimento da leggere prima di salvare
# atteso.txt       -> una riga per archivio: tipo|file|sorgente|byte non compressi
# meta.txt         -> host, nome, data, credenziali MySQL da usare, presenza di /root/.claude
# *.custom.list    -> gli eseguibili fuori dai pacchetti, uno per cartella di sistema
