#!/bin/bash
# stolen from https://magpi.raspberrypi.org/articles/raspberry-pi-recovery-partition

set -e

######################## prepare ################################
OUTPUT_DIR=/tmp/out
OUTPUT_DIR=/epicPiOS/out
mkdir -p $OUTPUT_DIR

apt update
apt -y install curl unzip uuid-runtime

######################## download and extract ################################
curl -C -  -L --output /epicPiOS/download/2021-05-07-raspios-buster-arm64.zip http://downloads.raspberrypi.org/raspios_arm64/images/raspios_arm64-2021-05-28/2021-05-07-raspios-buster-arm64.zip
curl -C - -L --output /epicPiOS/download/2021-05-07-raspios-buster-arm64-lite.zip http://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2021-05-28/2021-05-07-raspios-buster-arm64-lite.zip 

unzip -n /epicPiOS/download/2021-05-07-raspios-buster-arm64.zip -d /epicPiOS/images
unzip -n /epicPiOS/download/2021-05-07-raspios-buster-arm64-lite.zip -d /epicPiOS/images 


######################## calculate image size ################################
fdisk -lu /epicPiOS/images/2021-05-07-raspios-buster-arm64.img | grep img[1,2] | tr -s " " > /epicPiOS/images/partitions
fdisk -lu /epicPiOS/images/2021-05-07-raspios-buster-arm64-lite.img | grep img[1,2] | tr -s " " >> /epicPiOS/images/partitions

START_SECTOR=$(grep 2021-05-07-raspios-buster-arm64.img1 /epicPiOS/images/partitions | cut -d " " -f 2)
RASPIOS_BOOT_SECTORS=$(grep 2021-05-07-raspios-buster-arm64.img1 /epicPiOS/images/partitions | cut -d " " -f 4)
RASPIOS_MAIN_SECTORS=$(grep 2021-05-07-raspios-buster-arm64.img2 /epicPiOS/images/partitions | cut -d " " -f 4)
RASPIOS_LITE_MAIN_SECTORS=$(grep 2021-05-07-raspios-buster-arm64-lite.img2 /epicPiOS/images/partitions | cut -d " " -f 4)

let "NEEDED_IMAGE_SECTORS = START_SECTOR + RASPIOS_BOOT_SECTORS + RASPIOS_LITE_MAIN_SECTORS + 2 * RASPIOS_MAIN_SECTORS"
let "NEEDED_IMAGE_BYTES = 512 * NEEDED_IMAGE_SECTORS"
let "NEEDED_IMAGE_BLOCKS = NEEDED_IMAGE_BYTES / 4194304 + 1" # 4 megabyte blocks plus one extra block

######################## create blank image ################################
if [ ! -f $OUTPUT_DIR/2021-05-07-raspios-buster-arm64-restore.img ]; then
  dd if=/dev/zero status=progress bs=4194304 count=$NEEDED_IMAGE_BLOCKS > $OUTPUT_DIR/2021-05-07-raspios-buster-arm64-restore.img
fi


######################## partition image  ################################
UUIDRESTORE=$(uuidgen)
UUIDROOTFS=$(uuidgen)
PARTUUID=$(tr -dc 'a-f0-9' < /dev/urandom 2>/dev/null | head -c8)

let "START_PART2 = START_SECTOR + RASPIOS_BOOT_SECTORS"
let "SIZE_PART2 = RASPIOS_MAIN_SECTORS + RASPIOS_LITE_MAIN_SECTORS"
let "START_PART3 = START_PART2 + SIZE_PART2"

sfdisk $OUTPUT_DIR/2021-05-07-raspios-buster-arm64-restore.img <<EOL
label: dos
label-id: 0x${PARTUUID}
unit: sectors

2021-05-07-raspios-buster-arm64-restore.img1 : start=$START_SECTOR, size=$RASPIOS_BOOT_SECTORS, type=c
2021-05-07-raspios-buster-arm64-restore.img2 : start=$START_PART2, size=$SIZE_PART2, type=83
2021-05-07-raspios-buster-arm64-restore.img3 : start=$START_PART3, size=$RASPIOS_MAIN_SECTORS, type=83
EOL


######################## mount the images  ################################
losetup -v -f $OUTPUT_DIR/2021-05-07-raspios-buster-arm64-restore.img
partx -v --add /dev/loop0
losetup --show -f -P /epicPiOS/images/2021-05-07-raspios-buster-arm64-lite.img
losetup --show -f -P /epicPiOS/images/2021-05-07-raspios-buster-arm64.img

dd if=/dev/loop2p1 of=/dev/loop0p1 status=progress bs=4M
dd if=/dev/loop2p2 of=/dev/loop0p3 status=progress bs=4M

dd if=/dev/loop1p2 of=/dev/loop0p2 status=progress bs=4M


################ configure and mount partitions  ############################
tune2fs /dev/loop0p2 -U ${UUIDRESTORE}
e2label /dev/loop0p2 recoveryfs
tune2fs /dev/loop0p3 -U ${UUIDROOTFS}
 
e2fsck -f /dev/loop0p2
resize2fs /dev/loop0p2
 
mkdir -p mnt/restoreboot
mkdir -p mnt/restore_recovery
mkdir -p mnt/restore_rootfs
 
mount /dev/loop0p1 mnt/restoreboot
mount /dev/loop0p2 mnt/restore_recovery
mount /dev/loop0p3 mnt/restore_rootfs

########################### set the boot partition ##################### 
DISK_IDENTIFIER=$(fdisk -lu $OUTPUT_DIR/2021-05-07-raspios-buster-arm64-restore.img | grep "Disk identifier:" | awk '{ print $NF }')
 
sed -i "s/root=PARTUUID=\S*/root=PARTUUID=$DISK_IDENTIFIER-2/g" mnt/restoreboot/cmdline.txt

########################### create the reset scripts  ##################### 
cp /epicPiOS/boottoroot mnt/restoreboot/boottoroot 
cp /epicPiOS/boottorecovery mnt/restoreboot/boottorecovery
cp /epicPiOS/restoreroot mnt/restoreboot/restoreroot
chmod +x mnt/restoreboot/boottoroot
chmod +x mnt/restoreboot/boottorecovery
chmod +x mnt/restoreboot/restoreroot

######################### fix fstab ##############################
UUID_BOOT=$(blkid -o export /dev/loop0p1 | egrep 'PARTUUID=' | cut -d'=' -f2)

cat << EOF > mnt/restore_rootfs/etc/fstab
proc                     /proc  proc    defaults          0       0
UUID=${UUID_BOOT}  /boot  vfat    defaults          0       2
UUID=${UUIDROOTFS}  /      ext4    defaults,noatime  0       1
EOF

cat << EOF > mnt/restore_recovery/etc/fstab
proc                    /proc  proc    defaults          0       0
UUID=${UUIDROOTFS}       /boot  vfat    defaults          0       2
UUID=${UUIDRESTORE}    /      ext4    defaults,noatime  0       1
EOF


######################### snapshot root partition ##############################
dd if=/dev/loop0p3 of=mnt/restore_recovery/rootfs.img status=progress bs=4M


######################### unmount everytiong  ##############################
umount -f mnt/restoreboot
umount -f mnt/restore_recovery
umount -f mnt/restore_rootfs
partx -d /dev/loop0
losetup --detach-all

