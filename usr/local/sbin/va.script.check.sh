#!/bin/bash

# versione locale
if [ -f "/usr/local/etc/va.script.version" ]; then
    LOCAL="$(cat /usr/local/etc/va.script.version)"
else
    LOCAL="0"
fi

# versione remota, quella del ramo master su GitHub
REMOTE="$(va.curl.get.value.sh https://raw.githubusercontent.com/istricesrl/calabash/master/usr/local/etc/va.script.version)"

# controllo
if [ -z "$REMOTE" ]; then
    echo "impossibile verificare la presenza di aggiornamenti degli script"
else
    if [ "$LOCAL" -lt "$REMOTE" ]; then
    echo "devi aggiornare gli script"
    else
    echo "script aggiornati"
    fi
fi
