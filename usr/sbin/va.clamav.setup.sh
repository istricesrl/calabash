#!/bin/bash

# installazione servizi
apt-get install clamav clamav-daemon

# avvio del server
systemctl start clamav-daemon
systemctl start clamav-freshclam
