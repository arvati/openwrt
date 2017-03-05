#!/bin/sh

# autoprovision stage 2: this script will be executed upon boot if the extroot was successfully mounted (i.e. rc.local is run from the extroot overlay)

. /root/autoprovision-functions.sh

installPackages()
{
#    signalAutoprovisionWaitingForUser

    until (opkg update)
    do
        log "opkg update failed. No internet connection? Retrying in 15 seconds..."
        sleep 15
    done

#    signalAutoprovisionWorking

    log "Autoprovisioning stage2 is about to install packages"

    # switch ssh from dropbear to openssh (needed to install sshtunnel)
    #opkg remove dropbear
    #opkg install openssh-server openssh-sftp-server sshtunnel

    #/etc/init.d/sshd enable
    #mkdir /root/.ssh
    #chmod 0700 /root/.ssh
    #mv /etc/dropbear/authorized_keys /root/.ssh/
    #rm -rf /etc/dropbear

    # CUSTOMIZE
    # install some more packages that don't need any extra steps
    opkg install lua luci ppp-mod-pppoe screen mc zip unzip logrotate
    opkg install luci-ssl base-files busybox ddns-scripts dnsmasq dropbear firewall fstools hostapd-common ip6tables iptables iptables-mod-ipopt iw jshn jsonfilter kernel kmod-ath kmod-ath9k kmod-ath9k-common kmod-cfg80211 kmod-crypto-aes kmod-crypto-arc4 kmod-crypto-core kmod-gpio-button-hotplug kmod-ip6tables kmod-ipt-conntrack kmod-ipt-core kmod-ipt-ipopt kmod-ipt-nat kmod-ipv6 kmod-ledtrig-usbdev kmod-lib-crc-ccitt kmod-mac80211 kmod-nf-conntrack kmod-nf-conntrack6 kmod-nf-ipt kmod-nf-ipt6 kmod-nf-nat kmod-nf-nathelper kmod-nls-base kmod-slhc kmod-usb-core kmod-usb2 libblobmsg-json libc libgcc libip4tc libip6tc libiwinfo libiwinfo-lua libjson-c libjson-script liblua libncurses libnl-tiny libpthread libubox libubus libubus-lua libuci libuci-lua libxtables luci-app-ddns luci-app-firewall luci-base luci-lib-ip luci-lib-nixio luci-mod-admin-full luci-proto-ipv6 luci-proto-ppp luci-theme-bootstrap mtd netifd odhcp6c odhcpd opkg procd rpcd swconfig terminfo uboot-envtools ubox ubus ubusd uci uhttpd uhttpd-mod-ubus usign wpad-mini

    #opkg install base-files ddns-scripts dnsmasq dropbear firewall iptables-mod-ipopt kmod-ipt-ipopt libncurses libpthread luci-app-ddns luci-base luci-theme-bootstrap odhcpd rpcd terminfo uboot-envtools uhttpd uhttpd-mod-ubus

    # this is needed for the vlans on tp-link 3020 with only a single hw ethernet port
    #opkg install kmod-macvlan ip

    # just in case if we were run in a firmware that didn't already had luci
    /etc/init.d/uhttpd enable
    /etc/init.d/uhttpd start

    # install either more packages - now we have enough space
    #opkg install ppp ppp-mod-pppol2tp ppp-mod-pptp kmod-ppp kmod-pppoe wireless-tools iptables kmod-nf-nathelper-extra luci-proto-ppp
    opkg install mount-utils swap-utils e2fsprogs fdisk
    opkg install blkid kmod-usb-storage-extras
    #opkg install kmod-usb-uhci kmod-usb-ohci
    #opkg install kmod-mmc
    opkg install kmod-loop kmod-fs-nfs-common kmod-fs-nfs kmod-fs-exportfs kmod-fs-cifs kmod-nls-utf8 nfs-utils nfs-kernel-server nfs-kernel-server-utils nfs-server unfs3 openssh-sftp-server
    #opkg install strongswan-default ip iptables-mod-nat-extra djbdns-tools

}

autoprovisionStage2()
{
    log "Autoprovisioning stage2 speaking"

    # TODO this is a rather sloppy way to test whether stage2 has been done already, but this is a shell script...
    if [ $(uci get system.@system[0].log_type) == "file" ]; then
        #log "Seems like autoprovisioning stage2 has been done already. Running stage3."
        #/root/autoprovision-stage3.py
        log "Seems like autoprovisioning stage2 has been done already."
    else
#        signalAutoprovisionWorking

        # CUSTOMIZE: with an empty argument it will set a random password and only ssh key based login will work.
        # please note that stage2 requires internet connection to install packages and you most probably want to log in
        # on the GUI to set up a WAN connection. but on the other hand you don't want to end up using a publically
        # available default password anywhere, therefore the random here...
        setRootPassword "kimax"

        installPackages

        crontab - <<EOF
# */10 * * * * /root/autoprovision-stage3.py
0 0 * * * /usr/sbin/logrotate /etc/logrotate.conf
EOF

        mkdir -p /var/log/archive

        # logrotate is complaining without this directory
        mkdir -p /var/lib

        uci set system.@system[0].log_type=file
        uci set system.@system[0].log_file=/var/log/syslog
        uci set system.@system[0].log_size=0

        uci commit
        sync
        reboot
    fi
}

#autoprovisionStage2
