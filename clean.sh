#!/bin/bash
sudo umount PI_BOOT
sudo umount PI_ROOT
rm -rf PI_BOOT
rm -rf PI_ROOT

sudo umount RECOVERY 
rm -d RECOVERY

for file in "boot.tar.xz" "boot.tar" "os.json" "partitions.json" "partition_setup.sh" "root.tar.xz" "root.tar" "raspios.img" "noobs" "noobs.zip" "raspios.zip"
do
  rm -rf $file
done

