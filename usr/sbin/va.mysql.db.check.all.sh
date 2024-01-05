#!/bin/bash

# NOTA
# ripara i database

# log
logger "$0"

mysqlcheck --defaults-extra-file=/etc/mysql.conf --all-databases --check-upgrade --auto-repair
mysqlcheck --defaults-extra-file=/etc/mysql.conf --all-databases --optimize
mysql_upgrade --defaults-extra-file=/etc/mysql.conf --force
service mysql restart
