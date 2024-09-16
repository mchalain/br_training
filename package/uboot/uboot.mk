FIRMWARES_DIR=$(BINARIES_DIR)/rpi-firmware/
RPI_FIRMWARE_CONFIG_TXT=$(BR2_EXTERNAL_TRAINING_PATH)/package/uboot/config_uboot.txt
define UBOOT_RPI_FIRMWARE_INSTALL
	#$(INSTALL) -m 755 -D $(@D)/u-boot.bin $(FIRMWARES_DIR)/u-boot.bin
	$(INSTALL) -m 644 -D $(RPI_FIRMWARE_CONFIG_TXT) $(FIRMWARES_DIR)/config_uboot.txt
	mv $(FIRMWARES_DIR)/config.txt $(FIRMWARES_DIR)/config_kernel.txt
	ln -ns config_uboot.txt $(FIRMWARES_DIR)/config.txt
endef
UBOOT_POST_INSTALL_TARGET_HOOKS+=UBOOT_RPI_FIRMWARE_INSTALL
