#!/bin/sh

# autoprovision stage 1: this script will be executed upon boot without a valid extroot (i.e. when rc.local is found and run from the internal overlay)

. /root/autoprovision-functions.sh

autoprovisionStage1()
{
	log "Autoprovisioning stage1 speaking"
	local device="/dev/sda"
	#local type="overlay"
	local type="rootfs"
	local FOUND=1
	btrfs fi show -d "${device}" || FOUND=0
	if [ $FOUND == 0 ]; then
		setupExtroot "${type}" "${device}"
		sync
        	reboot
        else
        	log "Found BTRFS disk nothing done"
        	uci set fstab.@global[0].delay_root='15'
		uci set fstab.@global[0].anon_swap='0'
		uci set fstab.@global[0].anon_mount='0'
		uci set fstab.@global[0].auto_swap='0'
		uci set fstab.@global[0].auto_mount='0'
		uci set fstab.@global[0].check_fs='0'
        	uci commit fstab
        fi
}

autoprovisionStage1
