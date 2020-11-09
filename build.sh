#!/bin/bash

path=$(pwd)

curl -L http://downloads.raspberrypi.org/raspios_arm64/images/raspios_arm64-2020-08-24/2020-08-20-raspios-buster-arm64.zip --output raspios-buster-arm64.zip

unzip raspios-buster-arm64.zip

boot_size=$(sudo parted  2020-08-20-raspios-buster-arm64.img  -s print | grep fat32 | tr -s [:blank:] | cut -d " " -f4)
boot_size=${boot_size%??} # remove last two chars = MB
root_size=$(sudo parted  2020-08-20-raspios-buster-arm64.img  -s print | grep ext4 | tr -s [:blank:] | cut -d " " -f4)
root_size=${root_size%??} # remove last two chars = MB
echo boot_size=$boot_size
echo root_size=$root_size

sudo kpartx -av 2020-08-20-raspios-buster-arm64.img

sudo mkdir PI_BOOT
sudo mount /dev/mapper/loop0p1 PI_BOOT/
cd PI_BOOT/
sudo bsdtar --numeric-owner --format gnutar -cpf ../boot.tar .
boot_tarball_size=$(ls ../boot.tar -l --block-size=1MB |  tr -s [:blank:] | cut -d " " -f5)
echo boot_tarball_size=$boot_tarball_size
cd ..
sudo xz -9 -e boot.tar
boot_sha256sum=$(sha256sum boot.tar.xz | cut -d " " -f1)
sudo umount PI_BOOT/
sudo rm -rf PI_BOOT/

echo starting root ...

sudo mkdir PI_ROOT
sudo mount /dev/mapper/loop0p2 PI_ROOT/
cd PI_ROOT/
sudo bsdtar --numeric-owner --format gnutar --one-file-system -cpf ../root.tar .
root_tarball_size=$(ls ../root.tar -l --block-size=1MB |  tr -s [:blank:] | cut -d " " -f5)
echo root_tarball_size=$root_tarball_size
cd ..
sudo xz -9 -e root.tar
root_sha256sum=$(sha256sum root.tar.xz | cut -d " " -f1)
sudo umount PI_ROOT/
sudo rm -rf PI_ROOT/

sleep 1

sudo kpartx -dv  2020-08-20-raspios-buster-arm64.img 

cat >os.json <<EOF
{
    "description": "A port of Debian with the Raspberry Pi Desktop",
    "feature_level": 35120124,
    "kernel": "5.4",
    "name": "Raspberry Pi OS (64-bit)",
    "password": "raspberry",
    "release_date": "2020-08-20",
    "supported_hex_revisions": "2082,20d3,3111,3112,3114",
    "supported_models": [
        "Pi 3",
        "Pi 3 Model B Rev",
        "Pi 4"
    ],
    "url": "http://www.raspbian.org/",
    "username": "pi",
    "version": "buster"
}
EOF

cat >partitions.json <<EOF
{
    "partitions": [
        {
            "filesystem_type": "FAT",
            "label": "boot",
            "mkfs_options": "-F 32",
            "partition_size_nominal": ${boot_size},
            "uncompressed_tarball_size": ${boot_tarball_size},
            "want_maximised": false,
            "sha256sum": "${boot_sha256sum}"
        },
        {
            "filesystem_type": "ext4",
            "label": "root",
            "mkfs_options": "-O ^huge_file",
            "partition_size_nominal": ${root_size},
            "uncompressed_tarball_size": ${root_tarball_size},
            "want_maximised": true,
            "sha256sum": "${root_sha256sum}"
        }
    ]
}
EOF


cat >partition_setup.sh <<EOF
#!/bin/sh
set -ex

# shellcheck disable=SC2154
if [ -z "$part1" ] || [ -z "$part2" ]; then
  printf "Error: missing environment variable part1 or part2n" 1>&2
  exit 1
fi

mkdir -p /tmp/1 /tmp/2

mount "$part1" /tmp/1
mount "$part2" /tmp/2

sed /tmp/1/cmdline.txt -i -e "s|root=[^ ]*|root=${part2}|"
sed /tmp/2/etc/fstab -i -e "s|^[^#].* / |${part2}  / |"
sed /tmp/2/etc/fstab -i -e "s|^[^#].* /boot |${part1}  /boot |"

# shellcheck disable=SC2154
if [ -z "$restore" ]; then
  if [ -f /mnt/ssh ]; then
    cp /mnt/ssh /tmp/1/
  fi

  if [ -f /mnt/ssh.txt ]; then
    cp /mnt/ssh.txt /tmp/1/
  fi

  if [ -f /settings/wpa_supplicant.conf ]; then
    cp /settings/wpa_supplicant.conf /tmp/1/
  fi

  if ! grep -q resize /proc/cmdline; then
    if ! grep -q splash /tmp/1/cmdline.txt; then
      sed -i "s| quiet||g" /tmp/1/cmdline.txt
    fi
    sed -i 's| init=/usr/lib/raspi-config/init_resize.sh||' /tmp/1/cmdline.txt
  else
    sed -i '1 s|.*|& sdhci.debug_quirks2=4|' /tmp/1/cmdline.txt
  fi
fi

cp /mnt/os/raspios_arm64/provision.service /tmp/2/lib/systemd/system/provision.service
ln -s /lib/systemd/system/provision.service /tmp/2/etc/systemd/system/provision.service
cp /mnt/os/raspios_arm64/provision.sh /tmp/1/provision.sh
chmod 0755 /tmp/1/provision.sh
cp /mnt/os/raspios_arm64/blink_ip.service /tmp/2/lib/systemd/system/blink_ip.service
cp /mnt/os/raspios_arm64/blink_ip.timer /tmp/2/lib/systemd/system/blink_ip.timer
ln -s /lib/systemd/system/blink_ip.timer /tmp/2/etc/systemd/system/timers.target.wants/blink_ip.timer
ln -s /lib/systemd/system/systemd-time-wait-sync.service /tmp/2/etc/systemd/system/sysinit.target.wants/systemd-time-wait-sync.service
cp /mnt/os/raspios_arm64/blink_ip.sh /tmp/1/blink_ip.sh
chmod 0755 /tmp/1/blink_ip.sh
cp /mnt/os/raspios_arm64/factory_reset.sh /tmp/2/sbin/factory_reset.sh
chmod 0755 /tmp/2/sbin/factory_reset.sh

umount /tmp/1
umount /tmp/2
EOF
