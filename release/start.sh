#!/bin/sh
set -x #echo on

cd /home/pi/CAPLink

./startscript.sh 2>&1 | tee  /home/pi/CAPLink/s.log
