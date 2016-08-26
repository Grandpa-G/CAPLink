#!/bin/sh
set -x #echo on

cd /home/pi/CAPLink

chmod +x /release/startscript.sh
./release/startscript.sh 2>&1 | tee  /home/pi/CAPLink/start.log
