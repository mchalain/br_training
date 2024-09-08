# Simple buildroot project for Linux Embedded training

This project build buildroot image for:
 * Raspberry Pi4

## Setting
The host system must be a standard Linux distribution. A good choice may be Debian.

The packages to install:
 * build-essential
 * git
 * libssl-dev
 * minicom

The buildroot project must be downloaded any where on the PC. In the file we choice:  
  **/opt/buildroot**

## Building
Buildroot is a makefiles' collection and must be call from a console shell.

```shell
$ cd br_training
$ make -C /opt/buildroot O=$PWD/output BR2_EXTERNAL=$PWD training_rpi4_defconfig
...
$ cd output
$ make
```

## Installation
The generated image must be written on a SD card.
Take care of the device node of the card before to write, it is easy to **destroy** your file system

```shell
$ # after SD card insertion
$ sudo dmesg
...
[ 3788.343425] sd 4:0:0:0: [sdd] Attached SCSI removable disk
[ 3789.706161] EXT4-fs (sdd2): recovery complete
[ 3789.708194] EXT4-fs (sdd2): mounted filesystem with ordered data mode. Quota mode: none.
$ sudo umount /dev/sdd2
$ sudo dd if=images/sdcard.img of=/dev/sdd bs=1M

```

## Startup
 * Insert the SD card inside the board.
 * Plug the Serial to USB cable between the board and the PC host.
 * Open minicom on the PC host.
 * Plug the USB type C cable to the board from the alimentation.

