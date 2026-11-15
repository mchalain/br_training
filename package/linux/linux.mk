LINUX_BUILD_DEST   = $(STAGING_DIR)/usr/src/linux-$(LINUX_VERSION)/
LINUX_TRAINING_DIR = $(BR2_EXTERNAL_TRAINING_PATH)/package/linux/
LINUX_BUILD_FILTER = $(LINUX_TRAINING_DIR)build.filter

define LINUX_KERNEL_STAGING_INSTALL
  $(LINUX_MAKE_ENV) $(BR2_MAKE) $(LINUX_MAKE_FLAGS) -C $(@D) modules_prepare
  $(eval MODULES_VERSION=$(file < $(@D)/include/config/kernel.release))
  $(eval LINUX_BUILD_DEST=$(STAGING_DIR)/usr/src/linux-$(MODULES_VERSION))
  $(INSTALL) -d '$(LINUX_BUILD_DEST)'
  sed 's/@ARCH@/$(KERNEL_ARCH)/g' '$(LINUX_BUILD_FILTER)' \
	> '$(LINUX_DIR)/.linux-build.filter'
  rsync -a --prune-empty-dirs --delete --delete-excluded \
	--filter='merge $(LINUX_DIR)/.linux-build.filter' \
	'$(LINUX_DIR)/' '$(LINUX_BUILD_DEST)/'
  rm -f '$(LINUX_DIR)/.linux-build.filter'
  $(INSTALL) -D -m 644 $(@D)/include/config/kernel.release $(STAGING_DIR)/usr/include/linux/
  $(INSTALL) -d $(STAGING_DIR)/lib/modules/$(MODULES_VERSION)
  ln -s ../../../usr/src/linux-$(MODULES_VERSION)/ $(STAGING_DIR)/lib/modules/$(MODULES_VERSION)/build
endef
LINUX_POST_CONFIGURE_HOOKS+=LINUX_KERNEL_STAGING_INSTALL
#INUX_POST_BUILD_HOOKS+=LINUX_KERNEL_STAGING_INSTALL
  
define LINUX_KERNEL_STAGING_INSTALL_MODULE_SYMVERS
  $(INSTALL) -D -m 644 $(@D)/Module.symvers $(LINUX_BUILD_DEST)/Module.symvers
endef

LINUX_POST_BUILD_HOOKS+=LINUX_KERNEL_STAGING_INSTALL_MODULE_SYMVERS

define LINUX_SDK_INSTALL
	cat $(LINUX_TRAINING_DIR)/Makefile.in | \
		sed 's/@ARCH@/$(KERNEL_ARCH)/' | \
		sed 's,@CROSS_COMPILE@,$(notdir $(TARGET_CROSS)),' > $(HOST_DIR)/Makefile
endef

LINUX_POST_BUILD_HOOKS+=LINUX_SDK_INSTALL
