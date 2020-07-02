#!/bin/bash

# NOTA
# esegue la configurazione iniziale

# log
logger "$0"

# dimensioni della finestra di whiptail
VMOD=10
HMOD=70

# chiedo l'autorizzazione a procedere
whiptail	--title "setup server" \
		--yesno "Questo script ti guiderà nel setup del server. Vuoi procedere?" \
		$VMOD $HMOD

# procedo
if [[ "$?" -eq 0 ]]; then

    # CAMBIO HOSTNAME
    # per facilitare l'identificazione della macchina

    # link simbolico
    TITLE="nome completo (FQDN) della macchina"
    TEXT="Inserisci il nome completo della macchina (hostname e dominio)"
    OLDFQDN="$(hostname -f)"
    DEFAULT="$OLDFQDN"
    FQDN="$(whiptail --title "$TITLE" --inputbox "$TEXT" $VMOD $HMOD "$DEFAULT" 3>&1 1>&2 2>&3)"

    # imposto il nome della macchina
    hostnamectl set-hostname $FQDN
    sed -i -e "s/$OLDFQDN/$FQDN/g" /etc/hosts

    # SEZIONE SERVIZI
    # in questa sezione vengono installati i servizi erogati dalla macchina

    # SSH
    apt-get install ssh

    # exim4 - server di posta
    apt-get install exim4
    apt-get install gnutls-bin
    apt-get install libsasl2-modules
    /usr/share/doc/exim4-base/examples/exim-gencert

    # mailutils - utility per la posta
    apt-get install mailutils

    # monit - server di monitoraggio
    # NOTA monit non è più disponibile in Debian 10 e non sembrano esserci alternative valide
    # apt-get install monit

    # SEZIONE PROGRAMMI DI MONITORAGGIO
    # in questa sezione vengono installati programmi utili per tenere sotto controllo la macchina

    # iotop - utility per il controllo dell'I/O disco
    apt-get install iotop

    # htop - utility per visualizzare i processi
    apt-get install htop

    # iftop - utility per il controllo del traffico di rete
    apt-get install iftop

    # psmisc - utility per il controllo dei processi
    apt-get install psmisc

    # ncdu - utility per il controllo dello spazio usato su disco
    apt-get install ncdu

    # SEZIONE PROGRAMMI UTILI
    # in questa sezione vengono installati programmi utili per gestire il sistema

    # utility per il firewall
    apt-get install ethtool

    # utility per Latex
    apt-get install texlive-latex-base
    apt-get install doxygen-latex
    apt-get install texlive-lang-italian

    # utility per Bash
    apt-get install bash-completion

    # utility per Perl
    apt-get install libconfig-inifiles-perl

    # utility per il Debian keyring
    apt-get install debian-keyring debian-archive-keyring

    # utility per PostScript
    apt-get install a2ps

    # utility per la gestione delle release LSB
    apt-get install lsb-release

    # Midnight Commander
    apt-get install mc

    # links - un browser testuale
    apt-get install links

    # lsof
    apt-get install lsof

    # less - un visualizzatore di file testuale
    apt-get install less

    # ncftp - un client FTP a linea di comando
    apt-get install ncftp

    # curl - un client web a linea di comando
    apt-get install curl

    # ntp - un client per la sincronizzazione dell'orario
    apt-get install ntp

    # net-tools - utility per la rete
    apt-get install net-tools

    # speedtest-cli - un'utility per testare la velocità di rete
    apt-get install speedtest-cli

    # dsh - un tool per dare comandi a più macchine contemporaneamente
    apt-get install dsh

    # at - pianificatore di comandi
    apt-get install at

    # pwgen - generatore di password
    apt-get install pwgen

    # rsync
    apt-get install rsync

    # wget
    apt-get install wget

    # dnsutils - utility per l'interrogazione del DNS
    apt-get install dnsutils

    # whois - pacchetto di utility varie
    apt-get install whois

    # bzip2 - un programma di compressione
    apt-get install bzip2

    # nmap - un tool per il debug della rete
    apt-get install nmap

    # whiptail - interfaccia utente per gli script bash
    apt-get install whiptail

    # locales - pacchetto per la localizzazione
    apt-get install locales

    # gestione dei video
    apt-get install ffmpeg mediainfo

    # SEZIONE CONFIGURAZIONE
    # in questa sezione viene configurato il sistema

    # riconfigurazione della lingua
    dpkg-reconfigure locales

    # riconfigurazione del fuso orario
    dpkg-reconfigure tzdata

    # creazione chiavi SSH
    if [[ ! -e /root/.ssh/id_rsa ]]; then
	ssh-keygen
	cat /root/.ssh/id_rsa.pub
    fi

    # journal
    va.log.journal.sh "configurazione iniziale del sistema"

fi

# esco
exit $?

# NOTA
# questo script è relaunch safe, può essere eseguito tutte le volte che si vuole

# NOTA
# l'installazione di monit e munin, che nel vecchio script era inclusa, adesso va
# fatta a parte

# TO-DO
# va settata la mail dell'amministratore, ma questo implica il setup della posta,
# ad ogni modo bisogna che sistemistica@videoarts.eu riceva le notifiche
