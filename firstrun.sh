#!/bin/bash

set +e

CURRENT_HOSTNAME=`cat /etc/hostname | tr -d " \t\n\r"`

# set hostname to sd cards serial numaber
NEW_HOSTNAME=`lsblk /dev/mmcblk0  -n -o name,serial | grep '^mmcblk0' | xargs | cut -d " " -f 2`
echo $NEW_HOSTNAME>/etc/hostname
sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts

FIRSTUSER=`getent passwd 1000 | cut -d: -f1`
FIRSTUSERHOME=`getent passwd 1000 | cut -d: -f6`
echo "$FIRSTUSER:"'$5$rsPp6efRYf$H1tZf.Dz1sXr1olkxcFzRBfi11JZJ.6Pb.gQGRXJOPC' | chpasswd -e
systemctl enable ssh
cat >/etc/wpa_supplicant/wpa_supplicant.conf <<WPAEOF
country=CH
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
ap_scan=1

update_config=1
network={
	ssid="scratch"
	psk="8962scratch"
}

WPAEOF
chmod 600 /etc/wpa_supplicant/wpa_supplicant.conf
rfkill unblock wifi
for filename in /var/lib/systemd/rfkill/*:wlan ; do
  echo 0 > $filename
done
rm -f /etc/xdg/autostart/piwiz.desktop
rm -f /etc/localtime
echo "Europe/Zurich" >/etc/timezone
dpkg-reconfigure -f noninteractive tzdata
cat >/etc/default/keyboard <<KBEOF
XKBMODEL="pc105"
XKBLAYOUT="de"
XKBVARIANT=""
XKBOPTIONS=""
KBEOF
dpkg-reconfigure -f noninteractive keyboard-configuration
mv /boot/firstrun.sh /boot/firstrun.done
sed -i 's| systemd.run.*||g' /boot/cmdline.txt
apt-mark hold raspberrypi-kernel
exit 0
