#!/bin/bash

curl -sS https://dl.google.com/cloudagents/install-monitoring-agent.sh -o ~/install-monitoring-agent.sh
chmod +x ~/install-monitoring-agent.sh
~/install-monitoring-agent.sh
rm -f ~/install-monitoring-agent.sh
