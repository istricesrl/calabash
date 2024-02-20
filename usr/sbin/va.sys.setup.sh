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

    # riconfigurazione della lingua
    apt-get install -y locales
    dpkg-reconfigure locales

    # riconfigurazione del fuso orario
    dpkg-reconfigure tzdata

    # AGGIUNTA DNS
    echo "nameserver 8.8.8.8" >> /etc/resolv.conf
    echo "nameserver 8.8.4.4" >> /etc/resolv.conf
    echo "35.195.12.4	calabash.videoarts.it" >> /etc/hosts

    # SEZIONE SERVIZI
    # in questa sezione vengono installati i servizi erogati dalla macchina

    # SSH
    apt-get install -y ssh

    # exim4 - server di posta
    apt-get install -y exim4
    apt-get install -y gnutls-bin
    apt-get install -y libsasl2-modules
    /usr/share/doc/exim4-base/examples/exim-gencert

    # mailutils - utility per la posta
    apt-get install -y mailutils

    # monit - server di monitoraggio
    apt-get install -y monit

    # SEZIONE PROGRAMMI DI MONITORAGGIO
    # in questa sezione vengono installati programmi utili per tenere sotto controllo la macchina

    # iotop - utility per il controllo dell'I/O disco
    apt-get install -y iotop

    # htop - utility per visualizzare i processi
    apt-get install -y htop

    # iftop - utility per il controllo del traffico di rete
    apt-get install -y iftop

    # psmisc - utility per il controllo dei processi
    apt-get install -y psmisc

    # ncdu - utility per il controllo dello spazio usato su disco
    apt-get install -y ncdu

    # SEZIONE PROGRAMMI UTILI
    # in questa sezione vengono installati programmi utili per gestire il sistema

    # utility per il firewall
    apt-get install -y ethtool

    # utility per Latex
    apt-get install -y texlive-latex-base
    apt-get install -y doxygen-latex
    apt-get install -y texlive-lang-italian

    # utility per Bash
    apt-get install -y bash-completion

    # utility per Perl
    apt-get install -y libconfig-inifiles-perl

    # utility per il Debian keyring
    apt-get install -y debian-keyring debian-archive-keyring

    # utility per PostScript
    apt-get install -y a2ps

    # utility per JSON
    apt-get install -y jq

    # utility per la gestione delle release LSB
    apt-get install -y lsb-release

    # Midnight Commander
    apt-get install -y mc

    # links - un browser testuale
    apt-get install -y links

    # lsof
    apt-get install -y lsof

    # less - un visualizzatore di file testuale
    apt-get install -y less

    # ncftp - un client FTP a linea di comando
    apt-get install -y ncftp

    # curl - un client web a linea di comando
    apt-get install -y curl

    # ntp - un client per la sincronizzazione dell'orario
    apt-get install -y ntp

    # net-tools - utility per la rete
    apt-get install -y net-tools

    # ethtool - utility per la rete
    apt-get install -y ethtool

    # speedtest-cli - un'utility per testare la velocità di rete
    apt-get install -y speedtest-cli

    # dsh - un tool per dare comandi a più macchine contemporaneamente
    apt-get install -y dsh

    # at - pianificatore di comandi
    apt-get install -y at

    # pwgen - generatore di password
    apt-get install -y pwgen

    # rsync
    apt-get install -y rsync

    # wget
    apt-get install -y wget

    # dnsutils - utility per l'interrogazione del DNS
    apt-get install -y dnsutils

    # whois - pacchetto di utility varie
    apt-get install -y whois

    # bzip2 - un programma di compressione
    apt-get install -y bzip2

    # nmap - un tool per il debug della rete
    apt-get install -y nmap

    # whiptail - interfaccia utente per gli script bash
    apt-get install -y whiptail

    # whiptail - interfaccia utente per gli script bash
    apt-get install -y taskwarrior

    # gestione dei video
    apt-get install -y ffmpeg mediainfo

    # SEZIONE CONFIGURAZIONE
    # in questa sezione viene configurato il sistema

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

# REVISIONI
# 2020-07-02 controllo funzionamento su Debian 10 (buster)
