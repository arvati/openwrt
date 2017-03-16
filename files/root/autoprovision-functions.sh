#!/bin/sh

# utility functions for the various stages of autoprovisioning

# make sure that installed packages take precedence over busybox. see https://dev.openwrt.org/ticket/18523
PATH="/usr/bin:/usr/sbin:/bin:/sbin"


log()
{
    /usr/bin/logger -t autoprov -s $*
}

setRootPassword()
{
    local password=$1
    if [ "$password" == "" ]; then
        # set and forget a random password merely to disable telnet. login will go through ssh keys.
        password=$(</dev/urandom sed 's/[^A-Za-z0-9+_]//g' | head -c 22)
    fi
    #echo "Setting root password to '"$password"'"
    log "Setting root password"
    echo -e "$password\n$password\n" | passwd root
}

step() {
    echo -n "$@"
    STEP_OK=0
    [[ -w /tmp ]] && echo $STEP_OK > /tmp/step.$$
}

try() {
    # Check for `-b' argument to run command in the background.
    local BG=
    [[ $1 == -b ]] && { BG=1; shift; }
    [[ $1 == -- ]] && {       shift; }
    # Run the command.
    if [[ -z $BG ]]; then
        "$@"
    else
        "$@" &
    fi
    # Check if command failed and update $STEP_OK if so.
    local EXIT_CODE=$?
    if [[ $EXIT_CODE -ne 0 ]]; then
        STEP_OK=$EXIT_CODE
        [[ -w /tmp ]] && echo $STEP_OK > /tmp/step.$$
    fi
    return $EXIT_CODE
}

next() {
    [[ -f /tmp/step.$$ ]] && { STEP_OK=$(< /tmp/step.$$); rm -f /tmp/step.$$; }
    [[ $STEP_OK -eq 0 ]]  && echo_success || echo_failure
    echo
    return $STEP_OK
}

getPendriveSize()
{
    # this is needed for the mmc card in some (all?) Huawei 3G dongle.
    # details: https://dev.openwrt.org/ticket/10716#comment:4
    if [ -e /dev/sdb ]; then
        # force re-read of the partition table
        head -c 1024 /dev/sdb >/dev/null
    fi

    if (grep -q sdb /proc/partitions) then
        cat /sys/block/sdb/size
    else
        echo 0
    fi
}

setupExtroot()
{
	local type=$1
	local device=$2
	#dd if=/dev/zero of="${device}" bs=1M count=1
	wipefs --all "${device}"
	mkfs.btrfs -f -M -d dup -m dup -L extroot "${device}"
	log "Finished setting up filesystem"
	mkdir -p /mnt/extroot/
        #mount -t btrfs LABEL=extroot /mnt/extroot
        mount -t btrfs "${device}" /mnt/extroot
	if [ "${type}" == "overlay" ]; then
		btrfs subvolume create /mnt/extroot/overlay
		mkdir -p /mnt/extroot/overlay/upper/
		btrfs subvolume create /mnt/extroot/overlay/upper/home
		btrfs subvolume create /mnt/extroot/rootfs/upper/srv		
		mkdir -p /mnt/extroot/overlay/upper/etc/
    		cat >/mnt/extroot/overlay/upper/etc/rc.local <<EOF
/root/autoprovision-stage2.sh
exit 0
EOF
		uci get fstab.overlay && uci delete fstab.overlay
		uci set fstab.overlay=mount
		uci set fstab.overlay.target='/overlay'
		uci set fstab.overlay.fstype='btrfs'
		uci set fstab.overlay.device="${device}"
		local subvolid=$(btrfs subvolume list -t /mnt/extroot | grep overlay | cut -c1-3)
		uci set fstab.overlay.options='subvolid=/overlay'
		uci set fstab.overlay.enabled='1'
		uci get fstab.rootfs && uci set fstab.rootfs.enabled='0'
    	else
		btrfs subvolume create /mnt/extroot/rootfs
		btrfs subvolume create /mnt/extroot/rootfs/home
		btrfs subvolume create /mnt/extroot/rootfs/srv
		mkdir -p /tmp/introot
		mount --bind / /tmp/introot
		tar -C /tmp/introot -cvf - . | tar -C /mnt/extroot/rootfs -xf -
		umount /tmp/introot
		#rsync -avxH / /mnt/extroot/rootfs/
		mkdir -p /mnt/extroot/rootfs/etc/
    		cat >/mnt/extroot/rootfs/etc/rc.local <<EOF
/root/autoprovision-stage2.sh
exit 0
EOF
		uci get fstab.rootfs && uci delete fstab.rootfs
		uci set fstab.rootfs=mount
		uci set fstab.rootfs.target='/'
		uci set fstab.rootfs.fstype='btrfs'
		uci set fstab.rootfs.device="${device}"
		local subvolid=$(btrfs subvolume list -t /mnt/extroot | grep rootfs | cut -c1-3)
		uci set fstab.rootfs.options='subvolid=/rootfs'
		uci set fstab.rootfs.enabled='1'
		uci get fstab.overlay && uci set fstab.overlay.enabled='0'
    	fi
    	uci set fstab.@global[0].delay_root='15'
	uci set fstab.@global[0].anon_swap='0'
	uci set fstab.@global[0].anon_mount='0'
	uci set fstab.@global[0].auto_swap='0'
	uci set fstab.@global[0].auto_mount='0'
	uci set fstab.@global[0].check_fs='0'
    	#uci show fstab	
    	uci commit fstab 
	umount /mnt/extroot
	log "Finished setting up extroot"
}

