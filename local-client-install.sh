#!/bin/bash

in-target /bin/sh -c -- "apt install -y -q vim mc net-tools tcpdump links xserver-xorg-core xserver-xorg-video-fbdev firefox-esr xinit sawfish"
in-target /bin/sh -c -- "apt install -y -q sudo"
in-target /bin/sh -c -- "usermod -a -G sudo sysadmin"
in-target /bin/sh -c -- 'echo XKBMODEL=\"pc105\" > /etc/default/keyboard'
in-target /bin/sh -c -- 'echo XKBLAYOUT=\"de\" >> /etc/default/keyboard'
in-target /bin/sh -c -- 'echo XKBVARIANT=\"de_CH\" >> /etc/default/keyboard'
in-target /bin/sh -c -- 'echo XKBOPTIONS=\"\" >> /etc/default/keyboard'
in-target /bin/sh -c -- 'echo BACKSPACE=\"guess\" >> /etc/default/keyboard'

in-target /bin/sh -c -- 'echo "source /etc/network/interfaces.d/*" > /etc/network/interfaces'
in-target /bin/sh -c -- 'echo "auto lo" >> /etc/network/interfaces'
in-target /bin/sh -c -- 'echo "iface lo inet loopback" >> /etc/network/interfaces'
in-target /bin/sh -c -- 'echo "auto enp0s3" >> /etc/network/interfaces'
in-target /bin/sh -c -- 'echo "iface enp0s3 inet static" >> /etc/network/interfaces'
in-target /bin/sh -c -- 'echo "    address 192.168.110.2" >> /etc/network/interfaces'
in-target /bin/sh -c -- 'echo "    network 192.168.110.0" >> /etc/network/interfaces'
in-target /bin/sh -c -- 'echo "    netmask 255.255.255.0" >> /etc/network/interfaces'
in-target /bin/sh -c -- 'echo "    broadcast 192.168.110.255" >> /etc/network/interfaces'

in-target /bin/sh -c -- 'cp /etc/apt/sources.list /etc/apt/sources.list.bak'
in-target /bin/sh -c -- 'grep -v cdrom /etc/apt/sources.list.bak > /etc/apt/sources.list'
in-target /bin/sh -c -- 'apt update'

in-target /bin/sh -c -- 'echo "sawfish & firefox" >> /root/.xinitrc'
in-target /bin/sh -c -- 'echo "sawfish & firefox" >> /home/sysadmin/.xinitrc'
in-target /bin/sh -c -- 'chown sysadmin:sysadmin /home/sysadmin/.xinitrc'


poweroff
