# HOWTO install U-Boot on Raspberry Pi
**All descriptions are available inside the u-boot branch of the repository.**

## Introduction
The Raspberry Pi Board are is own bootloader installing inside the GPU memory for Pi 1,2,3,4 and inside eeprom for Pi 5.
It's useless to add U-Boot on Raspberry Pi, but...

This example shows the normal booting settup of a board.

We will use package's Makefile. To do that the project must contain am "external.mk" file containing the include of all Makefile of our packages.

```shell
br_training/output/$ cat <<EOF > ../external.mk
> include $(sort $(wildcard $(BR2_EXTERNAL_TRAINING_PATH)/package/*/*.mk))
> EOF
br_training/output/$ |
```

## Build the U-Boot binary
The BuildRoot offers the rules to build U-Boot for different targets and for Raspberry Pi,
as the configuration file is available inside the U-Boot source files.

The uniq difficulty is to set the build of U-Boot and give the name of the good configuration file.
The menu "*Bootloaders*" into *make menuconfig* allows to select "U-Boot" and the field "Board defconfig" must the wanted file without "_defconfig" suffix.

| Board   | arch  | configuration |
|---------|-------|---------------|
| Pi 3 b  | arm   | rpi\_3\_32b     |
| Pi 3 b  | arm64 | rpi\_3         |
| Pi 3 b+ | arm64 | rpi\_3\_b\_plus  |
| Pi 4 b  | arm   | rpi\_4\_32b     |
| Pi 4 b  | arm64 | rpi\_4         |

For Raspberry Pi 3 b+ board, we should apply a patch to support 32bits version. This is a fragment file for this board containing the name of the dts.

```shell
br_training/output/$ make menuconfig
...
br_training/output/$ grep -e ^BR2_TARGET_UBOOT .config
BR2_TARGET_UBOOT=y
BR2_TARGET_UBOOT_BOARD_DEFCONFIG="rpi_3_32b"
BR2_TARGET_UBOOT_CONFIG_FRAGMENT_FILES="$(BR2_EXTERNAL_TRAINING_PATH)/board/raspberrypi/uboot-rpi3_b_plus.frag"
...
br_training/output/$ cd ../board/raspberrypi
br_training/board/raspberrypi/$ cat <<EOF > uboot-rpi3_b_plus.frag
> CONFIG_DEFAULT_DEVICE_TREE="bcm2837-rpi-3-b-plus"
> EOF
br_training/board/raspberrypi/$ cd -
br_training/output/$ |
```

## Build the U-Boot startup script
The U-Boot bootloader may use at the startup to kind of binary:
	* *bootenv.bin* a database with a list of fields with one value for each.
	* *boot.scr* a script of u-boot shell, which will be executed at the startup.
We will use only the *boot.scr* file. To build it, we need to build some host tool, defined in the "*Host utilities*" menu of *make menuconfig*.
"*host u-boot tools*" and "*Generate a U-Boot boot script*" must be selected and "*U-Boot boot script source*" must contain the path to our script.

```shell
br_training/output/$ make menuconfig
...
br_training/output/$ grep -e ^BR2_PACKAGE_HOST_UBOOT .config
BR2_PACKAGE_HOST_UBOOT_TOOLS=y
BR2_PACKAGE_HOST_UBOOT_TOOLS_BOOT_SCRIPT=y
BR2_PACKAGE_HOST_UBOOT_TOOLS_BOOT_SCRIPT_SOURCE="$(BR2_EXTERNAL_TRAINING_PATH)/board/raspberrypi3/uboot_rpi3-b.txt"
br_training/ouput/$ |
```

Our script must :
	* set the name of the kernel found on the SD card.
	* load the kernel into RAM.
	* set the boot arguments for the kernel to find the rootfs on the second partition of the sdcard.
   	* jump to the kernel address with the u-Boot DTB already in memory as argument
```shell
br_training/output/$ cat <<EOF > ../board/raspberrypi3/uboot_rpi3-b.txt
> setenv kernel zImage
> fatload mmc 0:1 ${kernel_addr_r} ${kernel}
> fatload mmc 0:1 ${fdt_addr_r} ${fdtfile}
> setenv bootargs 'root=/dev/mmcblk0p2 rootwait'
> bootz ${kernel_addr_r} - ${fdt_addr}
> EOF
br_training/output/$ |
```

At this point the bootscript are built, but not installed to be inserted to the sdcard image..
To do that **we will use the HOOK`s system of BuildRoot**, from a Makefile available inside the project's package.

Fist we create our own uboot-tools package with its Makefile. This makefile haven't to contain package generation command. It must define:
	* A macro install the "boot.scr" the "images/rpi-firmware" directory,
	* new variable for the *HOST_UBOOT_TOOLS* package rules.

```shell
br_training/output/$ mkdir -p ../package/uboot-tools
br_training/output/$ cat <<EOF > ../package/uboot-tools/uboot-tools.mk
> define HOST_UBOOT_TOOLS_RPI_INSTALL_BOOT_SCRIPT
>   $(INSTALL) -m 0755 -D $(@D)/tools/boot.scr $(BINARIES_DIR)/rpi-firmware/boot.scr
> endef
> ifneq ($(BR2_PACKAGE_HOST_UBOOT_TOOLS_BOOT_SCRIPT_SOURCE),)
>   HOST_UBOOT_TOOLS_POST_INSTALL_HOOKS+=HOST_UBOOT_TOOLS_RPI_INSTALL_BOOT_SCRIPT
> endif
> EOF
br_training/output/$ |
```

## set the Raspberry Pi bootloader to use U-Boot and not Linux
The Raspberry Pi bootloader uses the "images/rpi-firmware/config.txt" to load the DeviceTree and start the kernel.

Instead to start the Linux kernel, we want to start U-Boot bootloader first. Then we must modify the "images/rpi-firmware/config.txt".
To do that we will rename the current file and copy our file as "config\_uboot.txt", and a link select the file to use during the SD card generation.

We will use th *HOOK*'s system of BuildRoot for twice, with the "uboot" package now.

```shell
br_training/output/$ mkdir -p ../package/uboot
br_training/output/$ cat <<EOF > ../package/uboot/config_uboot.txt
> dtoverlay=miniuart-bt
> enable_uart=1
> kernel=u-boot.bin
> disable_overscan=1
> kernel2=zImage
> EOF
br_training/output/$ cat <<EOF > ../package/uboot/uboot.mk
> FIRMWARES_DIR=$(BINARIES_DIR)/rpi-firmware/
> RPI_FIRMWARE_CONFIG_TXT=$(BR2_EXTERNAL_TRAINING_PATH)/package/uboot/config_uboot.txt
> define UBOOT_RPI_FIRMWARE_INSTALL
> 	#$(INSTALL) -m 755 -D $(@D)/u-boot.bin $(FIRMWARES_DIR)/u-boot.bin
> 	$(INSTALL) -m 644 -D $(RPI_FIRMWARE_CONFIG_TXT) $(FIRMWARES_DIR)/config_uboot.txt
> 	mv $(FIRMWARES_DIR)/config.txt $(FIRMWARES_DIR)/config_kernel.txt
> 	ln -ns config_uboot.txt $(FIRMWARES_DIR)/config.txt
> endef
> EOF
br_training/output/$ |
```

## Build the new image

Let's go
```shell
br_training/output/$ make
...
```

