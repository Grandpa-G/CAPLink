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

echo "$(date) $MUMBLE process for $SERIAL is being started"

echo "new curl" 
cd $CAPLINK/release
rm mumble.sh
curl -u caplink:mumble -O ftp://caplink.azwg.org/CAPLink/${SERIAL}/mumble.sh 
ls -l mumble.sh
echo "<<<<<<<<<<<<<<"
cat mumble.sh
echo "<<<<<<<<<<<<<<"

chmod +x mumble.sh 
echo " " 

df -h /root 
echo " " 
echo "new start.sh"  

echo "Checking for mumble update" 
cd $CAPLINK  
git reset --hard HEAD 
git pull 
git log --oneline -1 

chmod +x release/mumble
chmod +x release/update.sh
chmod +x mumble.sh
chmod +x release/start.sh
chmod +x release/startscript.sh
cp release/start.sh .
cp release/startscript.sh .
chmod +x start.sh
chmod +x startscript.sh
ls -l *.sh

echo "Running update.sh script" 
./release/update.sh $SERIAL 
cd $CAPLINK 

#curl -T /home/pi/.cache/lxsession/LXDE-pi/run.log -u caplink:mumble ftp://caplink.azwg.org/CAPLink/$SERIAL/

echo "starting speaker, setting GPIO" 
aplay -D plughw:1,0 SpeakerWorks.wav
sleep .5

gpio export 3 in
gpio -g mode 3 in
gpio export 2 in
gpio -g mode 2 in
gpio export 18 out

gpio export 4 out
gpio -g mode 4 clock


echo "GPIO read 3" 
if [ "$(gpio -g read 3)" -eq 0 ]; then
	aplay -D plughw:1,0  "PTT LED Blinking.wav"
	sleep .5

  while true; do

	echo "blink" 
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

	echo "speaker" 
	speaker-test -t sine -f 440 -c 2 -l 10
	echo "speaker test done" 

	echo "push to talk testing" 
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
	echo "push to talk done" 
   done

#send the start.log to server
	cd $CAPLINK/CAPLink/release

	cp $CAPLINK/start.log $SERIAL.log
	curl -T start.log -u caplink:mumble ftp://caplink.azwg.org/CAPLink/$SERIAL/
	cd $CAPLINK

	exit
fi
echo "GPIO read 2" 

if [ "$(gpio -g read 2)" -eq 0 ]; then
	aplay -D plughw:1,0  MumbleSkipped.wav
	sleep .5

	echo "mumble skipped" 

#send the start.log to server
	cd $CAPLINK/CAPLink/release

	cp $CAPLINK/start.log $SERIAL.log
	curl -T start.log -u caplink:mumble ftp://caplink.azwg.org/CAPLink/$SERIAL/
	cd $CAPLINK

	exit
fi
echo "mumbling" 

if ps ax | grep -v grep | grep $MUMBLE > /dev/null
then
#no client running so don't start another
#copy contents of script file to log
	echo "start of mumble script" 
	echo ">>>>>>>>>>>>>>>>" 
	cat $CAPLINK/CAPLink/release/mumble.sh >>$CAPLINK/start.log
	echo "<<<<<<<<<<<<<<<<" 
	echo "end of mumble script" 

	echo "$(date) $MUMBLE is already running" 

#send the start.log to server
	cp $CAPLINK/start.log $SERIAL.log
	curl -T start.log -u caplink:mumble ftp://caplink.azwg.org/CAPLink/$SERIAL/
	cd $CAPLINK
else
	aplay -D plughw:1,0  MumbleStarting.wav

	echo "$(date) $MUMBLE is being started" 

	gpio export 17 out
	gpio export 18 out
	gpio -g mode 18 out
	gpio -g write 18 0
	gpio -g mode 17 out
	gpio -g write 17 1

	gpio export 4 out
	gpio -g mode 4 clock

#copy contents of script file to log
	echo "start of mumble script" 
	echo ">>>>>>>>>>>>>>>>" 
	cat $CAPLINK/release/mumble.sh >>$CAPLINK/start.log
	echo "<<<<<<<<<<<<<<<<" 
	echo "end of mumble script" 

#send the start.log to server
	cp $CAPLINK/start.log $SERIAL.log
	curl -T start.log -u caplink:mumble ftp://caplink.azwg.org/CAPLink/$SERIAL/

./release/mumble.sh ${SERIAL} | tee -a  $CAPLINK/start.log

        echo "end of mumble session" 

#	gpio -g write 17 1
#	gpio -g write 18 0
#	echo "$(date) $MUMBLE is being stopped" >> $MUMBLE.log
fi
