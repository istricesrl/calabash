#!/bin/bash

cp -r /usr/local/share/doc/va.script/examples/etc/monit/* /etc/monit/
service monit restart
