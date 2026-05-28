#!/bin/bash

# NOTA
# esporta un database un un file SQL

# log
logger "$0 $1"

if [[ -n $1 ]]; then

    if [[ -n $2 ]]; then
        CONN=" -h $2 -u $3 -p$4"
    else
        CONN=" --defaults-extra-file=/etc/mysql.conf"
    fi

    /usr/bin/mysqldump \
	$CONN \
	--add-drop-table \
	--add-locks \
	--disable-keys \
	--extended-insert \
	--lock-tables \
	--quick \
	--set-charset \
	--routines \
	--single-transaction \
	--events \
	--no-data $1 \
	| sed 's/ AUTO_INCREMENT=[0-9]*\b//g' | grep -v '^--' | grep -v -e '^[[:space:]]*$' \
	| sed -E 's/DEFINER=`[a-z]+`@`[a-z0-9\.%]+`/DEFINER=CURRENT_USER()/g' | sed 's/ AUTO_INCREMENT=[0-9]*\b//g' > $5$1.sql

else

    # help
    echo "$0 <nomeDb>"

fi

# uscita
exit $?
