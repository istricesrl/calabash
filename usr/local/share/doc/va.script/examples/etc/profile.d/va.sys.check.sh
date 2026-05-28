#!/bin/bash

# pulitura schermo
clear

# script
va.apt.check.sh
va.script.check.sh

# spaziatore
echo

# controllo disco
df -h

# spaziatore
echo

# controllo disco
free -h

# spaziatore
echo

# controllo monit
va.monit.check.sh

# spaziatore
echo

# cose da fare sulla macchina
task status:pending list

# spaziatore
echo
