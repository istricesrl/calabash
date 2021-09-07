#!/bin/bash

cp -r /usr/share/doc/va.script/examples/etc/monit/* /etc/monit/
service monit restart
