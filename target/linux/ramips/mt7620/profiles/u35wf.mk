#
# Copyright (C) 2016 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/U35WF
	NAME:=U35WF
	PACKAGES:=-kmod-usb-core -kmod-usb2 -kmod-usb-ohci -kmod-ledtrig-usbdev \
		-kmod-mt76
endef

define Profile/U35WF/Description
	Support for Kimax U35WF
endef
$(eval $(call Profile,U35WF))
