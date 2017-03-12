#!/bin/sh
#GPIOCHIP=0
#GPIOCHIP=24
GPIOCHIP=40
#GPIOCHIP=72
BASE=$(cat /sys/class/gpio/gpiochip${GPIOCHIP}/base)
NGPIO=$(cat /sys/class/gpio/gpiochip${GPIOCHIP}/ngpio)
max=$(($BASE+$NGPIO))
gpio=$BASE
while [ $gpio -lt $max ] ; do
	echo $gpio > /sys/class/gpio/export
	[ -d /sys/class/gpio/gpio${gpio} ] && {
		echo out > /sys/class/gpio/gpio$gpio/direction

		echo "[GPIO$gpio] Trying value 0"
		echo 0 > /sys/class/gpio/gpio$gpio/value
		sleep 3s

		echo "[GPIO$gpio] Trying value 1"
		echo 1 > /sys/class/gpio/gpio$gpio/value
		sleep 3s

		echo $gpio > /sys/class/gpio/unexport
	}
	gpio=$((gpio+1))
done
