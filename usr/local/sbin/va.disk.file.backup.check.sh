#!/bin/bash

# UTILIZZO
# elenca i file che sembrano copie di sicurezza lasciate in giro nei percorsi indicati

# NOTA
# serve a intercettare le copie messe accanto all'originale con un suffisso appiccicato
# DOPO l'estensione vera, tipo sshd_config.20260827123000 oppure my.cnf.bak: quel nome
# nasconde l'estensione finale, e su Linux moltissimi meccanismi decidono in base a
# quella. Casi reali incontrati su un nostro server:
#
#   /etc/cron.daily/         run-parts esegue i file che ci trova
#   /etc/profile.d/          ogni shell fa il source di *.sh
#   regole ModSecurity       l'include e' rules/*.conf, e ID di regola duplicati
#                            impediscono ad Apache di ripartire
#   document root Apache     il FilesMatch che nega .bak .conf .key .pem .sql e' ancorato
#                            a fine nome, quindi pagina.php.bak.20260827 viene servita in
#                            chiaro: sorgente pubblico
#
# il modo giusto di fare una copia e' va.bak.sh, che mette l'identificativo nel nome della
# cartella e lascia al file il suo nome vero

# NOTA
# non segnala i backup creati dagli strumenti di sistema (*.dpkg-old, *.ucf-dist,
# passwd-, shadow-, ...) ne' i file spediti dai pacchetti che finiscono con una coda
# legittima (*.conf.example, *.yaml.skeleton, exim4.conf.template, my.cnf.fallback)

# NOTA
# per un controllo periodico, creare uno script in /etc/cron.* con la chiamata:
#
# #!/bin/bash
# va.disk.file.backup.check.sh /etc
#
# uscita: 0 se non trova nulla, 1 se trova qualcosa, cosi' e' usabile anche da monit

# verifico i parametri
if [ -n "$1" ]; then

    # log
    logger "$0 $*"

    TROVATI=$( find "$@" -type f -printf '%f\t%p\n' 2>/dev/null | awk '
	BEGIN { FS = "\t" }
	{
	    n = tolower($1); p = $2

	    # backup legittimi degli strumenti di sistema
	    if ( n ~ /\.(dpkg|ucf|distupgrade)-(old|new|dist|bak|remove)$/ ) next
	    if ( n ~ /^(passwd|group|shadow|gshadow|subuid|subgid)-$/ )     next

	    # suffissi che tradiscono una copia di servizio
	    sospetto = ( n ~ /\.(bak|old|orig|save|backup|copy|prev|swp)([._-].*)?$/ ) \
		    || ( n ~ /~$/ ) \
		    || ( n ~ /\.[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]([-_.].*)?$/ )

	    # estensione vera trovata in mezzo al nome invece che in fondo
	    mezzo  = ( n ~ /\.(conf|sh|json|yaml|yml|cnf|list|pem|key|crt|ini|rules|service|sql)\./ )

	    # ... ma se il nome FINISCE con una coda legittima non si tratta di una copia
	    codaok = ( n ~ /\.(conf|sh|json|yaml|yml|cnf|list|pem|key|crt|ini|rules|service|sql|md|txt|d|example|template|skeleton|fallback|sample|dist|default|in)$/ )

	    if ( sospetto || ( mezzo && ! codaok ) ) print p
	}' | sort )

    if [ -n "$TROVATI" ]; then

	echo "$TROVATI"
	exit 1

    fi

else

    # sinossi
    echo "$0 /PATH [/PATH ...]"

fi

# uscita
exit 0

# REVISIONI
# 2026-08-27 prima stesura
