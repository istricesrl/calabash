#!/bin/bash

# PATH
PATH="/sbin:/usr/sbin:/bin:/usr/bin"

# includo regole custom o uso quelle standard
if [ -f '/etc/firewall.conf' ]; then

    . '/etc/firewall.conf'

else

    # alzo il firewall
    firewall_start() {

	# output
	echo "firewall start"

    }

    # abbaso il firewall
    firewall_stop() {

	# output
	echo "firewall stop"

	# reset del firewall
	iptables -t mangle	-F
	iptables -t mangle	-Z
	iptables -t mangle	-P PREROUTING							ACCEPT
	iptables -t mangle	-P INPUT							ACCEPT
	iptables -t mangle	-P FORWARD							ACCEPT
	iptables -t mangle	-P OUTPUT							ACCEPT
	iptables -t mangle	-P POSTROUTING							ACCEPT

	iptables -t nat		-F
	iptables -t nat		-Z
	iptables -t nat		-P PREROUTING							ACCEPT
	iptables -t nat		-P OUTPUT							ACCEPT
	iptables -t nat		-P POSTROUTING							ACCEPT

	iptables -t filter	-F
	iptables -t filter	-Z
	iptables -t filter	-P INPUT							ACCEPT
	iptables -t filter	-P FORWARD							ACCEPT
	iptables -t filter	-P OUTPUT							ACCEPT

    }

fi

# esecuzione dello script
case "$1" in
    start|restart|*)
	firewall_stop
	firewall_start
    ;;
    stop)
	firewall_stop
    ;;
esac

# uscita
exit 0

# NOTE
# per installare il firewall:
#
# systemctl daemon-reload
# systemctl enable firewall.service
#
# per avviare il firewall:
#
# service firewall start
#
# per abbassare il firewall:
#
# service firewall stop
#
# lo script /etc.firewall.conf è in pratica un sostituto di questo script,
# dovrebbe contenere la ridichiarazione delle funzioni 	firewall_stop(),
# firewall_start() e firewall_restart(); deve iniziare comunque con #!/bin/bash
#
# l'installazione del firewall richiede /etc/systemd/system/firewall.service
#
# NOTA questo serve per risolvere il problema della connessione bloccata
# su "Sending env LANG = it_IT.UTF-8", aggiungere a firewall_start() la riga seguente:
# ethtool -K $WANIF tx off rx off
#






