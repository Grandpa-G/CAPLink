#!/bin/sh
set -vx #echo on
MUMBLE='mumble:'
CAPLINK='/home/pi/CAPLink'

SERIAL="$(cat /proc/cpuinfo | grep Serial | cut -d ':' -f 2)"
SERIAL="$(echo "${SERIAL}" | sed -e 's/^[[:space:]]*//')"


cd $CAPLINK
pwd

#send the start.log even though it might get overwritten below
cp $CAPLINK/start.log $SERIAL.log
curl -T start.log -u caplink:mumble ftp://caplink.azwg.org/CAPLink/$SERIAL/

echo "$(date) $MUMBLE process for $SERIAL is being started" > $CAPLINK/start.log

echo "new curl" >> $CAPLINK/start.log
cd $CAPLINK/release
rm mumble.sh
curl -u caplink:mumble -O ftp://caplink.azwg.org/CAPLink/${SERIAL}/mumble.sh |tee -v -a ${CAPLINK}/start.log

echo "wget" >> $CAPLINK/start.log
#wget --ftp-user=caplink --ftp-password=mumble ftp://caplink.azwg.org/CAPLink/$SERIAL/mumble.sh |tee -a $CAPLINK/start.log
chmod +x mumble.sh >> $CAPLINK/start.log
echo " " >> $CAPLINK/start.log

df -h /root >> $CAPLINK/start.log
echo " " >> $CAPLINK/start.log
echo "new start.sh"  >> $CAPLINK/start.log

echo "Checking for mumble update" >> $CAPLINK/start.log
cd $CAPLINK  >> $CAPLINK/start.log
git reset --hard HEAD >> $CAPLINK/start.log
git pull >> $CAPLINK/start.log
git log --oneline -1 >> $CAPLINK/start.log

chmod +x release/mumble
chmod +x release/update.sh
chmod +x mumble.sh >> $CAPLINK/start.log

echo "Running update.sh script" >> $CAPLINK/start.log
./release/update.sh  >> $CAPLINK/start.log
cd $CAPLINK >> $CAPLINK/start.log

echo "starting speaker, setting GPIO" >> $CAPLINK/start.log
aplay -D plughw:1,0 SpeakerWorks.wav
sleep .5

gpio export 3 in
gpio -g mode 3 in
gpio export 2 in
gpio -g mode 2 in
gpio export 18 out

gpio export 4 out
gpio -g mode 4 clock


echo "GPIO read 3" >> $CAPLINK/start.log
if [ "$(gpio -g read 3)" -eq 0 ]; then
	aplay -D plughw:1,0  "PTT LED Blinking.wav"
	sleep .5

  while true; do

	echo "blink" >> $CAPLINK/start.log
	for value in 1 2 3 4 5 6 7 8 9 10
	do
		echo "LED ON $value"
		gpio -g write 18 1
		sleep 1.
		gpio -g write 18 0
		sleep 1.
	done

	aplay -D plughw:1,0  TestingSpeakers.wav
	sleep .5

	echo "speaker" >> $CAPLINK/start.log
	speaker-test -t sine -f 440 -c 2 -l 10
	echo "speaker test done" >> $CAPLINK/start.log

	echo "push to talk testing" >> $CAPLINK/start.log
	aplay -D plughw:1,0  PushToTalk.wav
	sleep .5

	gpio -g write 18 0

	for value in 1 2 3
	do
		gpio -g write 18 1
		sleep 3.2m
		gpio -g write 18 0
		sleep 10s
	done
	gpio -g write 18 0
	echo "push to talk done" >> $CAPLINK/start.log
   done

#send the start.log to server
	cd $CAPLINK/CAPLink/release

	cp $CAPLINK/start.log $SERIAL.log
	curl -T start.log -u caplink:mumble ftp://caplink.azwg.org/CAPLink/$SERIAL/
	cd $CAPLINK

	exit
fi
echo "GPIO read 2" >> $CAPLINK/start.log

if [ "$(gpio -g read 2)" -eq 0 ]; then
	aplay -D plughw:1,0  MumbleSkipped.wav
	sleep .5

	echo "mumble skipped" >> $CAPLINK/start.log

#send the start.log to server
	cd $CAPLINK/CAPLink/release

	cp $CAPLINK/start.log $SERIAL.log
	curl -T start.log -u caplink:mumble ftp://caplink.azwg.org/CAPLink/$SERIAL/
	cd $CAPLINK

	exit
fi
echo "mumbling" >> $CAPLINK/start.log

if ps ax | grep -v grep | grep $MUMBLE > /dev/null
then
#no client running so don't start another
#copy contents of script file to log
	echo "start of mumble script" >> $CAPLINK/start.log
	echo ">>>>>>>>>>>>>>>>" >> $CAPLINK/start.log
	cat $CAPLINK/CAPLink/release/mumble.sh >>$CAPLINK/start.log
	echo "<<<<<<<<<<<<<<<<" >> $CAPLINK/start.log
	echo "end of mumble script" >> $CAPLINK/start.log

	echo "$(date) $MUMBLE is already running" >> $CAPLINK/start.log

#send the start.log to server
	cp $CAPLINK/start.log $SERIAL.log
	curl -T start.log -u caplink:mumble ftp://caplink.azwg.org/CAPLink/$SERIAL/
	cd $CAPLINK
else
	aplay -D plughw:1,0  MumbleStarting.wav

	echo "$(date) $MUMBLE is being started" >> $CAPLINK/start.log

	gpio export 17 out
	gpio export 18 out
	gpio -g mode 18 out
	gpio -g write 18 0
	gpio -g mode 17 out
	gpio -g write 17 1

	gpio export 4 out
	gpio -g mode 4 clock

#copy contents of script file to log
	echo "start of mumble script" >> $CAPLINK/start.log
	echo ">>>>>>>>>>>>>>>>" >> $CAPLINK/start.log
	cat $CAPLINK/release/mumble.sh ${SERIAL} >>$CAPLINK/start.log
	echo "<<<<<<<<<<<<<<<<" >> $CAPLINK/start.log
	echo "end of mumble script" >> $CAPLINK/start.log

#send the start.log to server
	cp $CAPLINK/start.log $SERIAL.log
	curl -T start.log -u caplink:mumble ftp://caplink.azwg.org/CAPLink/$SERIAL/

./release/mumble.sh

        echo "end of mumble session" >> $CAPLINK/start.log

#	gpio -g write 17 1
#	gpio -g write 18 0
#	echo "$(date) $MUMBLE is being stopped" >> $MUMBLE.log
fi
