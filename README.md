# epicPiOS

An always resettable Operationg System based on respios. There are two flavors, one desktop version and one server version. Idea from [MagPi](https://magpi.raspberrypi.com/articles/raspberry-pi-recovery-partition) code manly copied from PJ Evans [github repo]https://github.com/mrpjevans/raspbian_restore).

## Important Notes
Upgrading the kernel may break the reset capability. For this reason, raspberrypi-kernel package is set on hold with ```apt-mark hold raspberrypi-kernel```.
see issue: https://github.com/einfachIT/epicPiOS/issues/27

## Usage
1. Dowwnload zip from https://drive.google.com/file/d/1vzAD91In2SJPU6bSp5QYZjtqc8LWPEpH/view?usp=sharing
2. Image your sd card with the raspberry pi imager.
3. Boot your rapspi with the new sd card
4. To factory reset your pi use: ```sudo /boot/boot_to_recovery restore```

To only switch between booting to recovery partition and normal root partition use ```sudo /boot/boot_to_recovery``` and ```sudo /boot/boot_to_root``` without any options.

## Build
1. checkout repo
2a. ```docker run -t -v /dev:/dev -v $(pwd):/epicPiOS --privileged ubuntu:focal /bin/bash -c 'cd epicPiOS; ./epic-server-answers | ./create_epicPiOS'```
2b. ```docker run -t -v /dev:/dev -v $(pwd):/epicPiOS --privileged ubuntu:focal /bin/bash -c 'cd epicPiOS; ./epic-desktop-answers | ./create_epicPiOS'```

resulting image is then stored in ./tmp

