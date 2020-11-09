#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

if [ ! -d /mnt/recovery ]; then 
 mkdir /mnt/recovery 
fi 

if ! mountpoint -q /mnt/recovery/ ; then 
 mount /dev/mmcblk0p1 /mnt/recovery 
fi 

sed -i 's/^/runinstaller /' /mnt/recovery/recovery.cmdline
mv /mnt/recovery/wpa_supplicant.conf.bak /mnt/recovery/wpa_supplicant.conf

reboot now
