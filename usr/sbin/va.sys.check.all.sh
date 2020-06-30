#!/bin/bash

# NOTA
# controlla lo stato del sistema

# eseguo i controlli presenti
for i in $(ls /usr/sbin/va.*.check.sh); do
    $i
done

# NOTA
# è possibile eseguire questo script al login in modo da visualizzare
# subito eventuali problemi; per farlo, il modo più semplice è creare un link
# simbolico in /etc/profile.d
#
# NOTA
# poiché i test possono comportare uso di risotse o invio di messaggi, non è
# indicato eseguirli all'avvio sulle macchine a cui si fa l'accesso di frequente
#
# NOTA
# il demone SSH mostra al login /etc/motd, e imposta le variabili d'ambiente
# da /etc/environment e ~/.pam_environment; quando una shell di login viene eseguita,
# i seguenti file sono letti nell'ordine:
#
# /etc/profile
# /etc/bash.bashrc
# ~/.bash_profile
#
# il file /etc/profile esegue tutti gli script con estensione .sh presenti in
# /etc/profile.d
#
