MYDRIVER_VERSION = 1.0
MYDRIVER_SITE = $(call github,mchalain,kernel-exercices,module.1)
MYDRIVER_SOURCE = mydriver-module.1.tar.gz
MYDRIVER_LICENSE = BSD-2
MYDRIVER_LICENSE_FILES = LICENSE

MYDRIVER_MODULE_MAKE_OPTS = KDIR=$(LINUX_DIR)
$(eval $(kernel-module))
$(eval $(generic-package))
