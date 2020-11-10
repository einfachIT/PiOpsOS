#!/bin/sh
set -ex

# shellcheck disable=SC2154
if [ -z "" ] || [ -z "" ]; then
  printf "Error: missing environment variable part1 or part2n" 1>&2
  exit 1
fi

mkdir -p /tmp/1 /tmp/2

mount "" /tmp/1
mount "" /tmp/2

sed /tmp/1/cmdline.txt -i -e "s|root=[^ ]*|root=|"
sed /tmp/2/etc/fstab -i -e "s|^[^#].* / |  / |"
sed /tmp/2/etc/fstab -i -e "s|^[^#].* /boot |  /boot |"

# shellcheck disable=SC2154
if [ -z "" ]; then
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

umount /tmp/1
umount /tmp/2
