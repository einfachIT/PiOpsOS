#!/bin/bash
sudo umount PI_BOOT
sudo umount PI_ROOT
rm -rf PI_BOOT
rm -rf PI_ROOT
umount /media/recovery
rm -d /media/recovery

for file in "boot.tar.xz" "boot.tar" "os.json" "partitions.json" "partition_setup.sh" "root.tar.xz" "root.tar" "2020-08-20-raspios-buster-arm64.img" "noobs" "noobs.zip" "raspios-buster-arm64.zip"
do
  rm -rf $file
done

