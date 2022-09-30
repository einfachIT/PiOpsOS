#!/bin/bash

set +e

CURRENT_HOSTNAME=`cat /etc/hostname | tr -d " \t\n\r"`

# set hostname to sd cards serial numaber
NEW_HOSTNAME=`lsblk /dev/mmcblk0  -n -o name,serial | grep '^mmcblk0' | xargs | cut -d " " -f 2`
echo $NEW_HOSTNAME>/etc/hostname
sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts

#copied from official raspi-imager firstrun
FIRSTUSER=`getent passwd 1000 | cut -d: -f1`
FIRSTUSERHOME=`getent passwd 1000 | cut -d: -f6`
if [ -f /usr/lib/raspberrypi-sys-mods/imager_custom ]; then
   /usr/lib/raspberrypi-sys-mods/imager_custom enable_ssh
else
   systemctl enable ssh
fi
if [ -f /usr/lib/userconf-pi/userconf ]; then
   /usr/lib/userconf-pi/userconf 'pi' '$5$w0pHM4Tsis$rr5lEiw2tj62u5iVGZE2oDLQrn9kyr3l50yz9k2YNA3'
else
   echo "$FIRSTUSER:"'$5$w0pHM4Tsis$rr5lEiw2tj62u5iVGZE2oDLQrn9kyr3l50yz9k2YNA3' | chpasswd -e
   if [ "$FIRSTUSER" != "pi" ]; then
      usermod -l "pi" "$FIRSTUSER"
      usermod -m -d "/home/pi" "pi"
      groupmod -n "pi" "$FIRSTUSER"
      if grep -q "^autologin-user=" /etc/lightdm/lightdm.conf ; then
         sed /etc/lightdm/lightdm.conf -i -e "s/^autologin-user=.*/autologin-user=pi/"
      fi
      if [ -f /etc/systemd/system/getty@tty1.service.d/autologin.conf ]; then
         sed /etc/systemd/system/getty@tty1.service.d/autologin.conf -i -e "s/$FIRSTUSER/pi/"
      fi
      if [ -f /etc/sudoers.d/010_pi-nopasswd ]; then
         sed -i "s/^$FIRSTUSER /pi /" /etc/sudoers.d/010_pi-nopasswd
      fi
   fi
fi
if [ -f /usr/lib/raspberrypi-sys-mods/imager_custom ]; then
   /usr/lib/raspberrypi-sys-mods/imager_custom set_wlan 'scratch' '156942a575d6c7b3fa0904e3eb9ccb9e392989f016905da9c7d055e7849d2906' 'CH'
else
cat >/etc/wpa_supplicant/wpa_supplicant.conf <<'WPAEOF'
country=CH
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
ap_scan=1

update_config=1
network={
	ssid="scratch"
	psk=156942a575d6c7b3fa0904e3eb9ccb9e392989f016905da9c7d055e7849d2906
}

WPAEOF
   chmod 600 /etc/wpa_supplicant/wpa_supplicant.conf
   rfkill unblock wifi
   for filename in /var/lib/systemd/rfkill/*:wlan ; do
       echo 0 > $filename
   done
fi
if [ -f /usr/lib/raspberrypi-sys-mods/imager_custom ]; then
   /usr/lib/raspberrypi-sys-mods/imager_custom set_keymap 'ch'
   /usr/lib/raspberrypi-sys-mods/imager_custom set_timezone 'Europe/Zurich'
else
   rm -f /etc/localtime
   echo "Europe/Zurich" >/etc/timezone
   dpkg-reconfigure -f noninteractive tzdata
cat >/etc/default/keyboard <<'KBEOF'
XKBMODEL="pc105"
XKBLAYOUT="ch"
XKBVARIANT=""
XKBOPTIONS=""

KBEOF
   dpkg-reconfigure -f noninteractive keyboard-configuration
fi
mv /boot/firstrun.sh /boot/firstrun.done
sed -i 's| systemd.run.*||g' /boot/cmdline.txt
apt-mark hold raspberrypi-kernel
exit 0
