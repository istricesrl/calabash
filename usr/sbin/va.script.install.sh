#!/bin/bash

# log
logger "$0"

apt-get update && apt-get upgrade
apt-get install wget unzip
wget https://github.com/istricesrl/calabash/archive/refs/heads/master.zip
unzip -qq ./master.zip
cp -R ./calabash-master/* /
rm -rf ./master.zip
rm -rf ./calabash-master
