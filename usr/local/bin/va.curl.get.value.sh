#!/bin/bash

# NOTA
# legge un URL e restituisce il valore letto

va.txt.trim.sh $(curl -sS $1)

# NOTA
# -sS non mostra errori e barre di avanzamento
