#!/bin/bash

# NOTA
# rimuove spazi bianchi e andate a capo dall'inizio e dalla fine di una stringa

echo -n ${1//[$'\t\r\n ']}

# NOTA
# // sta per il comando tr
