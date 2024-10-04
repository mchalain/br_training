# Simple buildroot project for Linux Embedded training

This project build buildroot image for:
 * Raspberry Pi4
 * Raspberry Pi3

## Hostpot wifi HOWTO
**All actions described inside this chapter are already done in this repository branch.**

### Introduction
The BuildRoot configuration generated a very light and simple firmware. The system uses Busybox and SysinitV infrastructure.

The SysinitV init application is available on the target system to the "/sbin/init" binary
(for us this is a link to "/bin/busybox", look to the busybox documentation to understand the busybox usage).
The **init** application will read the "/etc/inittab" file (available in "target/etc/inittab").

This one force **init** to :
 * mount the partitions
 * launch all "/etc/init.d/SXX* scripts with "start" as argument during the startup and "stop" during the ending.
 * open the console login tool

The following installation will create several files inside "target/etc/init.d/" directory to finilize the system setup and
to start the services.

### Applications

The hostpost Wifi needs 3 new packages:
 * hostapd
 * dnsmasq
 * iptables

The setting is done from the command:
```shell
br_training/output/$ make menuconfig
```

### Ovelay settings
We will overwrite a several files on the target system before the system disk generation. To do that we need to create a directory
inside the project where we will write the files in a same directory tree than the target system.

```shell
br_training/output/$ cd ..
br_training/$ mkdir -p overlay/etc/network/interfaces.d/
br_training/$ mkdir -p overlay/etc/init.d/
br_training/$ mkdir -p overlay/etc/modules-load.d/
br_training/$ cd output
```

After that, BuildRoot must be configurated to use this directory:
```shell
br_training/output/$ make menuconfig
 / ROOTFS_OVERLAY
 set to $(BR2_EXTERNAL_TRAINING_PATH)/overlay
 quit
br_training/output/$ grep ROOTFS_OVERLAY .config
ROOTFS_OVERLAY="$(BR2_EXTERNAL_TRAINING_PATH)/overlay"
```

### Network settings
The ethernet and wlan interfaces must be set.

#### Network eth0 interface
This interface must detect the cable plugin and the dhcpcd service must request a new IP address.
The BuildRoot configuration allows to set the configuration directly from the command:
```shell
br_training/output/$ make menuconfig
 / SYSTEM_DHCP
 y
 quit
br_training/output$ |
```
This will insert eth0 configuration lines into "target/etc/network/interfaces" file.

**At this point BuildRoot is ready for a first installation. It will create a primary image that we will modify with the overlay.**
```shell
br_training/output/$ make
...
br_training/output$ |
```

#### Network wlan0 interface
*The Raspberry Pi may support two wireless interface at the same time, but here we will use only one.*

As the Network settup is done from the "target/etc/network/interfaces"file, and BuildRoot modify this file for eth0, we will need to
use the overlay to overwrite this file. Another solution should be a new package with a Makefile to modify the file. This last solution
is the best, but more complex and not see here (look my br\_wifi repository)

As the overlay directory is ready, the first step is to copy the current "target/etc/network/interfaces" file into "../overlay/etc/network".
And we will add a new line to force the system to read file from the "/etc/network/interfaces.d" directory.

```shell
br_training/output/$ cp target/etc/network/interfaces ../overlay/etc/network/
br_training/output/$ cd ..
br_training/$ echo "source-dir /etc/network/interfaces.d" >> overlay/etc/network/interfaces
br_training/$ |
```

Now the wlan0 setting must be written inside a new "overlay/etc/network/interfaces.d/wlan0" file
```shell
br_training/$ cat <<EOF > overlay/etc/network/interfaces.d/wlan0
> auto wlan0
> iface wlan0 inet static
>  address 192.168.176.254
>  netmask 255.255.255.0
> EOF
br_training/$ cd output
br_training/output$ |
```
The wireless network will be set on 192.168.176.0 this address will be use by our dhcp service.

#### Network data forwarding
The Linux kernel doesn't allow to transfer data from a network to an other by default. This must be configurated at the boot time
(very old version of Linux needs to be configurated at the build time). Two solutions are availables:
 * we use **sysctl** command.
 * we write into a kernel virtual file "/proc/sys/net/ipv4/ip\_forward".

To enable the network forwarding at each boot, we will add an initialization script into "overlay/etc/init.d/" directory. This file
must be named "S35forwarding" to be used during the **init** step.

```shell
br_training/output/$ cd ../overlay/etc/init.d/
br_training/overlay/etc/init.d/$ cat <<EOF > forwarding.sh
> #!/bin/sh
> 
> sysctl -w net.ipv4.ip_forward=1
> EOF
br_training/overlay/etc/init.d/$ ln -s forwarding.sh S35forwarding
br_training/overlay/etc/init.d/$ cd -
br_training/output/$ |
```

### Hostapd Settings

The hostapd package provides a default configuration file. This one must be modified to secure our hostspot.
As the network interface we copy default file from target directory to the overlay directory and modify this one.

```shell
br_training/output/$ cp target/etc/hostapd.conf ../overlay/etc/
br_training/output/$ cd ..
br_training/$ sed -i 's/^ssid=.*/ssid=training/' overlay/etc/hostapd.conf
br_training/$ sed -i 's/^\#wpa=.*/wpa=2/' overlay/etc/hostapd.conf
br_training/$ sed -i 's/^\#wpa_passphrase=.*/wpa_passphrase=training/' overlay/etc/hostapd.conf
br_training/$ sed -i 's/^\#wpa_key_mgmt=.*/wpa_key_mgmt=WPA-PSK/' overlay/etc/hostapd.conf
br_training/$ sed -i 's/^eap_server=/\#eap_server=/' overlay/etc/hostapd.conf
br_training/$ cd output
br_training/output/$ |
```
All this commands may be done from a text editor, instead the sed commands.
 * The first change names our wireles network to "training¨.
 * The 2d, 3d and 4d will set the wpa authentication and use "training" as connection passphrase.
 * The last one will fix an error inside hostapd as the "eap\_server" is not built inside our hostapd binary.

The BuildRoot hostapd package is not completed and the startup file is missing. All startup file are available
inside "target/etc/init.d" directory. The BuildRoot team preconises to copy and modify the "target/etc/init.d/S01syslogd" file.
It's what we do to create "overlay/etc/init.d/hostapd.sh" file.

Currently our "target/etc/init.d/hostapd.sh" will be not launched by **init**, to do it we create a link to our script.

```shell
br_training/output/$ cp target/etc/init.d/S01syslog ../overlay/etc/init.d/hostapd.sh
br_training/output/$ cd ../overlay/etc/init.d/
br_training/overlay/etc/init.d/$ sed -i 's/^DAEMON=.*/DAEMON="hostapd"/' hostapd.sh
br_training/overlay/etc/init.d/$ sed -i 's/SYSLOGD_ARGS/DAEMON_ARGS/g' hostapd.sh
br_training/overlay/etc/init.d/$ sed -i 's/^DAEMON_ARGS=.*/DAEMON_ARGS="/etc/hostapd.conf"/' hostapd.sh
br_training/overlay/etc/init.d/$ sed -i 's,"/sbin/$DAEMON","/usr/sbin/$DAEMON"/' hostapd.sh
br_training/overlay/etc/init.d/$ ln -s hostapd.sh S80hostapd
br_training/overlay/etc/init.d/$ cd -
br_training/output$ |
```

### Dnsmasq settings
The *dnsmaq* configuration file is missing from package installation. The "build/dnsmasq-2.90/dnsmasq.conf.example" file is large and complex to modify.
We find here a simple one to set a dhcpd server which allows a range of address from 192.168.176.10 to 192.168.176.19
inside the same network than the wlan0 interface. We give the name "training.local" to the network and we use the google DNS for external DNS server.

```shell
br_training/output/$ cd ../overlay/etc/
br_training/overaly/etc/$ cat <<EOF > dnsmasq.conf
> bind-interfaces
> server=8.8.8.8
> domain-needed
> bogus-priv
> expand-hosts
> address=/\#/
> dhcp-range=uap0,192.168.176.10,192.168.176.19,12h
> local=/training.local/
> domain=training.local
> addn-hosts=/etc/dnsmasq-hosts.conf
> dhcp-option=option:router,192.168.176.254
> EOF
br_training/overaly/etc/$ echo "192.168.176.254 training.local" > dnsmasq-hosts.conf
br_training/overlay/etc/$ cd -
br_training/output$ |
```

### iptables settings
The *iptables* is a linux firewall configuration tools. But the real firewall are inside the Linux kernel. Then the firewall settings needs two parts.
#### firewall DB configuration
The tables are inside the kernel, and we must use the **iptables** application to push the lines to the kernel. As we want the same setting after each reboot,
we will use a configuration file which be read during the **init** step by "/etc/init.d/S35iptables" script.

We will not explain the current configuration, and we can find more information on the internet. A simple explanation is:
 * transfer data from wlan0 to eth0.
 * transfer data from eth0 to wlan0 when the connection is already established.
 * mask (hide) the wlan0's IP address into eth0 network.

```shell
br_training/output/$ cd ../overlay/etc/
br_training/overaly/etc/$ cat <<EOF > iptables.conf
> *filter
> :INPUT ACCEPT [0:0]
> :FORWARD ACCEPT [0:0]
> :OUTPUT ACCEPT [0:0]
> -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
> -A FORWARD -i wlan0 -o eth0 -j ACCEPT 
> COMMIT
> 
> *nat
> :PREROUTING ACCEPT [0:0]
> :INPUT ACCEPT [0:0]
> :OUTPUT ACCEPT [0:0]
> :POSTROUTING ACCEPT [0:0]
> -A POSTROUTING -o eth0 -j MASQUERADE
> COMMIT
> EOF
br_training/overlay/etc/$ cd -
br_training/output$ |
```
#### kernel configuration
At this point the firewall should be ready, but the kernel may need to load some modules to use the DB. Commonly we use **modprobe** load modules into the kernel.
The iptables needs to load several modules but only two must be forced, the rest are loaded as dependencies:
 * iptable-filter
 * iptable-nat

```shell
br_training/output/$ cd ../overlay/etc/
br_training/overaly/etc/$ cat <<EOF > modules-load.d/iptables.conf
> iptable-filter
> iptable-nat
> EOF
br_training/overlay/etc/$ cd -
br_training/output$ |
```

As the current BuildRoot configuration is very simple, we need to force the modules' loading during the **init** step. As for hostapd, we will create a new script into
"overlay/etc/init.d". This script is more simple and we will write it directly.

```shell
br_training/output/$ cd ../overlay/etc/init.d/
br_training/overaly/etc/init.d/$ cat <<EOF > modules.sh
> #!/bin/sh
> 
> case $1 in
>  start)
> 	ACTION=modprobe
> 	;;
>  stop)
> 	ACTION=rmmod
> 	;;
>  status)
> 	ACTION=modinfo
> 	;;
> esac
> 
> for file in $(ls /etc/modules-load.d)
> do
> 	for module in $(cat /etc/modules-load.d/$file)
> 	do
> 		$ACTION $module
> 	done
> done
> EOF
br_training/overlay/etc/init.d/$ ln -s modules.sh S20modules
br_training/overlay/etc/init.d/$ cd -
br_training/output$ |
```

**At this point BuildRoot is ready and the final build command must be launched**
```shell
br_training/output/$ make
...
br_training/output$ |
```

## Usage
### Settings
The host system must be a standard Linux distribution. A good choice may be Debian.

The packages to install:
 * build-essential
 * git
 * libssl-dev
 * minicom

The buildroot project must be downloaded any where on the PC. In the file we choice:  
  **/opt/buildroot**

### Building
Buildroot is a makefiles' collection and must be call from a console shell.

```shell
$ cd br_training
$ make -C /opt/buildroot O=$PWD/output BR2_EXTERNAL=$PWD training_rpi4_defconfig
...
$ cd output
$ make
```

### Installation
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
$ |
```

### Startup
 * Insert the SD card inside the board.
 * Plug the Serial to USB cable between the board and the PC host.
 * Open minicom on the PC host.
 * Plug the USB type C (or mini-USB depending on the board) cable to the board from the alimentation.

