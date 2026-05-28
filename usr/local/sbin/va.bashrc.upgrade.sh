#!/bin/bash

# log
logger "$0"

# AGGIORNAMENTI SPECIALI
cp /usr/local/share/doc/va.script/examples/root/.bashrc /root/
echo "CONTENUTO DEL FILE /root/.bashrc"
cat /root/.bashrc
cp /usr/local/share/doc/va.script/examples/etc/profile.d/va.sys.check.sh /etc/profile.d/
echo "SCRIPT PRESENTI IN /etc/profile.d/"
ls /usr/local/share/doc/va.script/examples/etc/profile.d/
