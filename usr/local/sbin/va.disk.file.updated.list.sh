#!/bin/bash

# NOTA
# elimina i file più vecchi di $2 giorni dal path $1

# log
logger "$0"

find . -printf '%Ts\t%TY/%Tm/%Td %TH:%TM\t%p\n' | sort -nr | cut -f2,3 | head -n 30
