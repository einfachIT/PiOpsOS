#!/bin/bash

ip=$(hostname -I | tr -d '[:space:]')

cmd=$(printf "%s " "0x08 0x0008 1d 02 01 06 03 03 aa fe ${#ip} 16 aa fe 10 00 02")
for (( i=0; i<${#ip}; i++ )); do
  cmd=${cmd}$(printf "%x " "'${ip:$i:1}")
done

sudo hciconfig hci0 up
sudo hciconfig hci0 leadv 3
sudo hcitool -i hci0 cmd $cmd
