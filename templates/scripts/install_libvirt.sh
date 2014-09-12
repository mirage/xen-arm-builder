LIBVIRT_FILE="libvirt.tar.gz"
LIBVIRT_URL="http://libvirt.org/sources/libvirt-1.2.8.tar.gz"

cleanup() {
	rm -f $LIBVIRT_FILE
	echo Exiting
}

trap cleanup EXIT

if [ ! -e "$LIBVIRT_FILE" ]; then
	wget $LIBVIRT_URL -O $LIBVIRT_FILE
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
	sudo cp templates/libvirt-bin.default /etc/default/libvirt-bin
fi

if [ ! -e "/etc/init.d/libvirt-bin" ]; then
	sudo cp templates/libvirt-bin.rc /etc/init.d/libvirt-bin && \
	sudo chmod +x /etc/init.d/libvirt-bin && \
	sudo update-rc.d libvirt-bin defaults
fi

sudo service libvirt-bin start
