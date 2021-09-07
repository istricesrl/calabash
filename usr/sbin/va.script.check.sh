#!/bin/bash

# versione locale
if [ -f "/etc/va.script.version" ]; then
    LOCAL="$(cat /etc/va.script.version)"
else
    LOCAL="0"
fi

# versione remota
REMOTE="$(va.curl.get.value.sh https://calabash.videoarts.it/va.current.version)"

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
