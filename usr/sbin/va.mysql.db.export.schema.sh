#!/bin/bash

# NOTA
# esporta un database un un file SQL

# log
logger "$0 $1"

if [[ -n $1 ]]; then

    /usr/bin/mysqldump \
	-h $2 \
	-u $3 \
	-p$4 \
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
	--no-data $1 | sed 's/ AUTO_INCREMENT=[0-9]*\b//g' | grep -v '^--' | grep -v '^\/\*' | grep -v -e '^[[:space:]]*$' > $5$1.sql

else

    # help
    echo "$0 <nomeDb>"

fi

# uscita
exit $?
