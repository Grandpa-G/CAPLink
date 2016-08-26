#!/bin/sh
set -x #echo on

echo "clear git lock"
rm .git/*.lock
echo "cleared"

echo "$1"
MUMBLE='mumble:'
CAPLINK='/home/pi/CAPLink'

SERIAL="$(cat /proc/cpuinfo | grep Serial | cut -d ':' -f 2)"
SERIAL="$(echo "${SERIAL}" | sed -e 's/^[[:space:]]*//')"

cd $CAPLINK
#send the mm.log even though it might get overwritten below
echo "send mm.log"
curl -T mm.log -u caplink:mumble ftp://caplink.azwg.org/CAPLink/$SERIAL/
echo "send m.log"
curl -T m.log -u caplink:mumble ftp://caplink.azwg.org/CAPLink/$SERIAL/

stat /home/pi/CAPLink/release/mumble.sh

echo "nothing to do"
