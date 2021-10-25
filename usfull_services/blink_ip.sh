#!/bin/bash

ip=$(hostname -I | cut -d "." -f 4 | tr -d '[:space:]')

echo none >/sys/class/leds/led0/trigger

sleep 1

for i in $(echo $ip | grep -o .)
do
  for ((n=0;n<$i;n++))
  do
   echo 1 >/sys/class/leds/led0/brightness
   sleep 0.2
   echo 0 >/sys/class/leds/led0/brightness
   sleep 0.2
  done
  sleep 0.5
done

sleep 1

echo mmc0 >/sys/class/leds/led0/trigger
