#!/bin/bash

# NOTA
# importa un file SQL in un database

# log
logger "$0"

# dimensioni della finestra di whiptail
VMOD=10
HMOD=70

# chiedo l'autorizzazione a procedere
whiptail	--title "setup server MySQL/MariaDb" \
		--yesno "Questo script ti guiderà nel setup di un server MySQL/MariaDb. Vuoi procedere?" \
		$VMOD $HMOD

# procedo
if [[ "$?" -eq 0 ]]; then

    # memoria totale base
    BASEMEM=$(free|awk '/^Mem:/{print $2}')
    BASEMB=$(( BASEMEM / 1024 ))

    # informo l'utente
    whiptail	--title "ATTENZIONE" \
		--msgbox "$(free -h)\n\nANNOTARE LA MEMORIA TOTALE ($BASEMB) PRIMA DI PROCEDERE!!!" \
		$(( VMOD+3 )) $(( HMOD+20 ))

    # innodb_buffer_pool_size
    TITLE="innodb_buffer_pool_size"
    TEXT="il valore suggerito è pari all'80% della RAM"
    DEFAULT=$(( BASEMB / 100 * 80 ))
    INNODB_BUFFER_POOL_SIZE=$(whiptail --title "$TITLE" --inputbox "$TEXT" $VMOD $HMOD "$DEFAULT" 3>&1 1>&2 2>&3)

    # innodb_log_file_size
    TITLE="innodb_log_file_size"
    TEXT="il valore suggerito è pari a 1/8 di innodb_log_file_size"
    DEFAULT=$(( INNODB_BUFFER_POOL_SIZE / 8 ))
    INNODB_LOG_FILE_SIZE=$(whiptail --title "$TITLE" --inputbox "$TEXT" $VMOD $HMOD "$DEFAULT" 3>&1 1>&2 2>&3)

    # innodb_buffer_pool_instances
    TITLE="innodb_buffer_pool_instances"
    TEXT="il valore suggerito è pari a 1 per ogni Gb assegnato a innodb_buffer_pool_size"
    DEFAULT=$(( BASEMB / 1024 ))
    INNODB_BUFFER_POOL_INSTANCES=$(whiptail --title "$TITLE" --inputbox "$TEXT" $VMOD $HMOD "$DEFAULT" 3>&1 1>&2 2>&3)

    # file di configurazione per i programmi tipo mysql
    FILECONF=/etc/mysql/mariadb.conf.d/50-server.cnf

    # backup dei files di configurazione coinvolti
    va.bak.sh $FILECONF /root/

    # TODO
    echo "[server]" > $FILECONF
    echo "" >> $FILECONF
    echo "[mysqld]" >> $FILECONF
    echo "user                            = mysql" >> $FILECONF
    echo "pid-file                        = /run/mysqld/mysqld.pid" >> $FILECONF
    echo "socket                          = /run/mysqld/mysqld.sock" >> $FILECONF
    echo "port                            = 3306" >> $FILECONF
    echo "basedir                         = /usr" >> $FILECONF
    echo "datadir                         = /var/lib/mysql" >> $FILECONF
    echo "tmpdir                          = /tmp" >> $FILECONF
    echo "lc-messages-dir                 = /usr/share/mysql" >> $FILECONF
    echo "bind-address                    = 0.0.0.0" >> $FILECONF
    echo "key_buffer_size                 = 16M" >> $FILECONF
    echo "thread_cache_size               = 128" >> $FILECONF
    echo "max_connections                 = 100" >> $FILECONF
    echo "table_open_cache                = 2048" >> $FILECONF
    echo "low_priority_updates            = 1" >> $FILECONF
    echo "tmp_table_size                  = 64M" >> $FILECONF
    echo "max_heap_table_size             = 64M" >> $FILECONF
    echo "query_cache_size                = 0" >> $FILECONF
    echo "query_cache_type                = 0" >> $FILECONF
    echo "log_error                       = /var/log/mysql/error.log" >> $FILECONF
    echo "expire_logs_days                = 10" >> $FILECONF
    echo "character-set-server            = utf8mb4" >> $FILECONF
    echo "collation-server                = utf8mb4_general_ci" >> $FILECONF
    echo "innodb_buffer_pool_size         = 2048M" >> $FILECONF
    echo "innodb_log_file_size            = 256M" >> $FILECONF
    echo "innodb_buffer_pool_instances    = 2" >> $FILECONF
    echo "innodb_file_per_table           = 1" >> $FILECONF
    echo "innodb_flush_log_at_trx_commit  = 2" >> $FILECONF
    echo "innodb_flush_method             = O_DIRECT" >> $FILECONF
    echo "" >> $FILECONF
    echo "[embedded]" >> $FILECONF
    echo "" >> $FILECONF
    echo "[mariadb]" >> $FILECONF
    echo "" >> $FILECONF
    echo "[mariadb-10.3]" >> $FILECONF
    echo "" >> $FILECONF

fi

# uscita
exit $?
