include $(TOPDIR)/rules.mk

PKG_NAME:=testpackage
PKG_VERSION:=1.0
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/testpackage
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=My First OPKG Package
  MAINTAINER:=Tester <tester@example.com>
endef

define Build/Compile
    # nothing to compile
endef

define Package/testpackage/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/usr/bin/hello.sh $(1)/usr/bin/hello.sh
endef

define Package/testpackage/postinst
#!/bin/sh
echo "Post-install: hello.sh has been installed!"
endef

define Package/testpackage/postrm
#!/bin/sh
echo "Post-remove: testpackage has been uninstalled!"
echo "Goodbye from hello.sh!"
exit 0
endef

$(eval $(call BuildPackage,testpackage))
