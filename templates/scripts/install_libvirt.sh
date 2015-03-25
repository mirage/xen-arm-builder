#!/bin/bash

# This script downloads and installs libvirt with Xen-support enabled. 
# Originally based on instructions from http://openmirage.org/wiki/libvirt-on-cubieboard

LIBVIRT_FILE="libvirt.tar.gz"
LIBVIRT_URL="http://libvirt.org/sources/libvirt-1.2.8.tar.gz"

if [ ! -e "$LIBVIRT_FILE" ]; then
	echo "Downloading $LIBVIRT_URL (to $LIBVIRT_FILE)"
	curl $LIBVIRT_URL '-L#o' $LIBVIRT_FILE
fi

mkdir libvirt
tar xvf $LIBVIRT_FILE -C libvirt --strip-components=1 && \
cd libvirt && \
./configure --prefix=/usr --localstatedir=/var  --sysconfdir=/etc --with-xen --with-qemu=no --with-gnutls --with-uml=no --with-openvz=no --with-vmware=no --with-phyp=no --with-xenapi=no --with-libxl=yes --with-vbox=no --with-lxc=no --with-esx=no  --with-hyperv=no --with-parallels=no --with-init-script=upstart && \
make clean && \
make -j3 && \
sudo make install && \
cd .. && \
rm -rf libvirt

if [ ! -e "/etc/default/libvirt-bin" ]; then
	echo 'start_libvirtd="yes"
libvirtd_opts="-d"' > /etc/default/libvirt-bin
fi

if [ ! -e "/etc/init/libvirtd.conf" ]; then
	if [ -e "/etc/event.d/libvirtd" ]; then # libvirtd 1.2.8 installs its upstart script here
		echo "libvirtd upstart config installed in /etc/event.d, moving to /etc/init"
		sudo mv -v /etc/event.d/libvirtd /etc/init/libvirtd.conf
	else
		echo "Unable to add libvirtd to upstart, startup script not found. You may have to configure it manually."
	fi
fi

sudo start libvirtd

echo "Reboot to enable libvirtd"
