#!/bin/sh
set -x #echo on

cd /home/pi/CAPLink

./release/startscript.sh 2>&1 | tee  /home/pi/CAPLink/start.log
