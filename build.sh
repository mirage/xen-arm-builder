#!/bin/sh -ex
# Build a Xen/Ubuntu image for a Cubieboard2

# sudo apt-get install kpartx sfdisk curl
IMG=${BOARD}.img
rm -f $IMG
qemu-img create $IMG 2G
parted ${IMG} --script -- mklabel msdos
parted ${IMG} --script -- mkpart primary fat32 2048s 264191s
parted ${IMG} --script -- mkpart primary ext4 264192s -1s
# Note: ext4 start sector MUST match value in templates/init.d/1st-boot

#printf ",32,C,*\n,4096,L\n,,8e\n\n\n" | sfdisk -uM -D $IMG
# cleanup loops
for loop in $(losetup -j ${IMG}); do
  loop_dev=$(echo $loop|cut -d ":" -f 1)
  umount $loop_dev || true
  losetup -d $loop_dev || true
done
losetup -f ${IMG}
LOOPDEV=$(losetup -j ${IMG} -o 0 | cut -d ":" -f 1)

# Create partition table
dd if=u-boot/build-${BOARD}/u-boot-sunxi-with-spl.bin of=${LOOPDEV} bs=1024 seek=8
SIZE=`fdisk -l ${LOOPDEV} | grep Disk | grep bytes | awk '{print $5}'`
CYLINDERS=`echo $SIZE/255/63/512 | bc`
WRKDIR=`pwd`

finish () {
  cd ${WRKDIR}
  sleep 5
  umount /mnt/proc || true
  umount /mnt/dev || true
  umount /mnt || true
  kpartx -d ${LOOPDEV} || true
  losetup -d ${LOOPDEV} || true
}

trap finish EXIT

MLOOPDEV=`echo $LOOPDEV | sed -e 's,/dev/,/dev/mapper/,g'`
kpartx -avs ${LOOPDEV}
mkfs.vfat ${MLOOPDEV}p1
mkfs.ext4 ${MLOOPDEV}p2

mount ${MLOOPDEV}p1 /mnt
cp boot/boot-${BOARD}.scr /mnt/boot.scr
cp linux/arch/arm/boot/zImage /mnt/vmlinuz
cp linux/arch/arm/boot/dts/sun7i-a20-cubieboard2.dtb /mnt/
cp linux/arch/arm/boot/dts/sun7i-a20-cubietruck.dtb /mnt/
cp xen/xen/xen /mnt/
umount /mnt

mount ${MLOOPDEV}p2 /mnt
tar -C /mnt -xf $ROOTFS
cd /mnt
mv binary/* .
rmdir binary
rsync -av ${WRKDIR}/linux-arm-modules/ /mnt/

# Copy the xen source to the target filesystem so we can build the tools on the 
# target after we boot (for now).
rsync -av --exclude='.git/' ${WRKDIR}/xen/ /mnt/usr/src/xen/

chown -R root:root /mnt/lib/modules/
cp ${WRKDIR}/templates/fstab etc/fstab
cp ${WRKDIR}/templates/interfaces etc/network/interfaces
rm -f etc/resolv.conf
cp ${WRKDIR}/templates/resolv.conf etc/resolv.conf
cp ${WRKDIR}/templates/hvc0.conf etc/init
cp --preserve=mode ${WRKDIR}/templates/init.d/1st-boot etc/init.d/
ln -s ../init.d/1st-boot etc/rcS.d/S10firstboot
mkdir -p lib/firmware
for f in ${FIRMWARE}; do
	cp -av "${WRKDIR}/linux-firmware/$f" lib/firmware
done

# Copy kernel to dom0 so it can be used in guests
cp ${WRKDIR}/linux/arch/arm/boot/zImage /mnt/root/dom0_kernel
# Copy example scripts to /root
cp -av ${WRKDIR}/templates/scripts /mnt/root


# Prevent services from starting while we build the image
echo 'exit 101' > usr/sbin/policy-rc.d
chmod a+x usr/sbin/policy-rc.d

mount -o bind /proc /mnt/proc
mount -o bind /dev /mnt/dev

# Enable the cross compiling environment in this chroot
#chroot /mnt dpkg --add-architecture armhf

echo "deb http://ppa.launchpad.net/avsm/ocaml42+opam12/ubuntu trusty main" > /mnt/etc/apt/sources.list.d/ppa-opam.list
chown root /mnt/etc/apt/sources.list.d/ppa-opam.list

chroot /mnt apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 5B2D0C5561707B09
chroot /mnt apt-get -y update
chroot /mnt apt-get -y upgrade
chroot /mnt apt-get -y install openssh-server ocaml ocaml-native-compilers camlp4-extra opam build-essential lvm2 aspcud pkg-config m4 libssl-dev libffi-dev parted avahi-daemon libnss-mdns iw batctl --no-install-recommends
chroot /mnt apt-get -y install libxml2-dev libdevmapper-dev libpciaccess-dev libnl-dev libgnutls-dev --no-install-recommends
chroot /mnt apt-get -y install tcpdump telnet nmap tshark tmux locate hping3 man-db --no-install-recommends
chroot /mnt apt-get -y install uuid-dev software-properties-common --no-install-recommends

# Packages required to compile the xen-tools natively when the board boots
chroot /mnt apt-get -y install libc6-dev:arm64 libncurses-dev:arm64 uuid-dev:arm64 libglib2.0-dev:arm64 libssl-dev:arm64 libssl-dev:arm64 libaio-dev:arm64 libyajl-dev:armhf python gettext gcc git libpython2.7-dev:armhf libfdt-dev:armhf libpixman-1-dev --no-install-recommends

# Install the necessar chroot cross compiling packages
#chroot /mnt apt-get -y install crossbuild-essential-armhf --no-install-recommends
#chroot /mnt apt-get -y install libc6-dev:armhf libncurses-dev:armhf uuid-dev:armhf libglib2.0-dev:armhf libssl-dev:armhf libssl-dev:armhf libaio-dev:armhf libyajl-dev:armhf python gettext gcc git libpython2.7-dev:armhf libfdt-dev:armhf --no-install-recommends

rm usr/sbin/policy-rc.d

echo UseDNS no >> etc/ssh/sshd_config

# Hostname
sed -i "s/linaro-developer/$BOARD/" etc/hosts
echo $BOARD > etc/hostname

# Build and install the custom xen tools, this has to be done here so that the 
# tools are linking against the correct libraries
#chroot /mnt cd /usr/src/xen && CONFIG_SITE=/etc/dpkg-cross/cross-config.armhf ./configure --build=x86_64-linux-gnu --host=arm-linux-gnueabihf
#chroot /mnt cd /usr/src/xen && make dist-tools CROSS_COMPILE=arm-linux-gnueabihf- XEN_TARGET_ARM=arm32
#chroot /mnt cd /usr/src/xen && make install-tools

# Mirage user
chroot /mnt userdel -r linaro
chroot /mnt useradd -s /bin/bash -G admin -m mirage -p mljnMhCVerQE6	# Password is "mirage" sed -i "s/linaro-developer/$BOARD/" etc/hosts 

# the resize application isn't on this image, so use a bash equivalent
cat >> /home/mirage/.profile <<EOF

if [ -n "$PS1" ]; then
    # bash equivalent of the "resize" command
    echo -en "\e[18t" # returns \e[8;??;??t
    IFS='[;'
    read -d t -s esc params
    set -- $params
    [ $# = 3 -a "$1" = 8 ] && shift
    [ $# != 2 ] && echo error >&2 && exit 1
    stty rows "$1" cols "$2"
fi
EOF

# OPAM init
OPAM_ROOT=/home/mirage/.opam
OPAM_REPO=/home/mirage/git/opam-repository
git clone https://github.com/ocaml/opam-repository.git /mnt/${OPAM_REPO}
chroot /mnt chown -R mirage ${OPAM_REPO}
chroot /mnt opam init ${OPAM_REPO} -y --root=${OPAM_ROOT}
# chroot /mnt opam repo add mirage https://github.com/mirage/mirage-dev.git --root=${OPAM_ROOT}
# chroot /mnt opam update --root=${OPAM_ROOT} # due to a bug in 1.1.1 (fixed in 1.2)
chroot /mnt chown -R mirage /home/mirage
