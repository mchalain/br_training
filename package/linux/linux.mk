LINUX_TRAINING_DIR = $(BR2_EXTERNAL_TRAINING_PATH)/package/linux/
LINUX_BUILD_FILTER = $(LINUX_TRAINING_DIR)build.filter

define LINUX_KERNEL_STAGING_PREPARE
  $(LINUX_MAKE_ENV) $(BR2_MAKE) $(LINUX_MAKE_FLAGS) -C $(@D) modules_prepare
endef
LINUX_POST_CONFIGURE_HOOKS+=LINUX_KERNEL_STAGING_PREPARE

MODULES_VERSION=$(file < $(LINUX_DIR)/include/config/kernel.release)
LINUX_BUILD_DEST=$(STAGING_DIR)/usr/src/linux-$(MODULES_VERSION)
define LINUX_KERNEL_STAGING_INSTALL
  echo $(MODULES_VERSION)
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
LINUX_PRE_BUILD_HOOKS+=LINUX_KERNEL_STAGING_INSTALL
  
define LINUX_KERNEL_STAGING_INSTALL_MODULE_SYMVERS
  $(INSTALL) -D -m 644 $(@D)/Module.symvers $(LINUX_BUILD_DEST)/Module.symvers
endef

LINUX_POST_BUILD_HOOKS+=LINUX_KERNEL_STAGING_INSTALL_MODULE_SYMVERS

OS_ID := $(shell . /etc/os-release && echo $$ID)
OS_VERSION := $(shell . /etc/os-release && echo $$VERSION_ID)
BASE_IMAGE := $(OS_ID):$(OS_VERSION)

define LINUX_SDK_INSTALL
	cat $(LINUX_TRAINING_DIR)/Makefile.in | \
		sed -e 's/@ARCH@/$(KERNEL_ARCH)/'  \
		    -e 's,@CROSS_COMPILE@,$(notdir $(TARGET_CROSS)),' > $(HOST_DIR)/Makefile
endef

LINUX_POST_BUILD_HOOKS+=LINUX_SDK_INSTALL
