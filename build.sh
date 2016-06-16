#!/bin/sh -ex
# Build a Xen/Ubuntu image for a Cubieboard2

# sudo apt-get install kpartx sfdisk curl
IMG=${BOARD}.img
rm -f $IMG
qemu-img create $IMG 3G
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
MNTBOOT=/mnt/xen-arm-boot
MNTROOTFS=/mnt/xen-arm-rootfs

finish () {
  cd ${WRKDIR}
  sleep 5
  umount ${MNTROOTFS}/proc || true
  umount ${MNTROOTFS}/dev/pts || true
  umount ${MNTROOTFS}/dev || true
  umount ${MNTROOTFS} || true
  kpartx -d ${LOOPDEV} || true
  losetup -d ${LOOPDEV} || true
  rmdir ${MNTROOTFS}
}

trap finish EXIT

MLOOPDEV=`echo $LOOPDEV | sed -e 's,/dev/,/dev/mapper/,g'`
kpartx -avs ${LOOPDEV}
mkfs.vfat ${MLOOPDEV}p1
mkfs.ext4 ${MLOOPDEV}p2

mkdir ${MNTBOOT}
mount ${MLOOPDEV}p1 ${MNTBOOT}
cp boot/boot-${BOARD}.scr ${MNTBOOT}/boot.scr
cp linux/arch/arm/boot/zImage ${MNTBOOT}/vmlinuz
cp linux/arch/arm/boot/dts/sun7i-a20-cubieboard2.dtb ${MNTBOOT}/
cp linux/arch/arm/boot/dts/sun7i-a20-cubietruck.dtb ${MNTBOOT}/
cp xen/xen/xen ${MNTBOOT}/
umount ${MNTBOOT}
rmdir ${MNTBOOT}

mkdir ${MNTROOTFS}
mount ${MLOOPDEV}p2 ${MNTROOTFS}
tar -C ${MNTROOTFS} -xf $ROOTFS
cd ${MNTROOTFS}
mv binary/* .
rmdir binary
rsync -av ${WRKDIR}/linux-arm-modules/ ${MNTROOTFS}/

# Copy the xen source to the target filesystem so we can build the tools on the 
# target after we boot (for now).
rsync -av --exclude='.git/' ${WRKDIR}/xen/ ${MNTROOTFS}/usr/src/xen/

# Copy the config.cache file to the /usr/src/xen directory so it can be used as 
# the configuration for the xen-tools cross compilation.
cp ${WRKDIR}/config/config.cache ${MNTROOTFS}/usr/src/xen/

chown -R root:root ${MNTROOTFS}/lib/modules/
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
cp ${WRKDIR}/linux/arch/arm/boot/zImage ${MNTROOTFS}/root/dom0_kernel
# Copy example scripts to /root
cp -av ${WRKDIR}/templates/scripts ${MNTROOTFS}/root


# Prevent services from starting while we build the image
echo 'exit 101' > usr/sbin/policy-rc.d
chmod a+x usr/sbin/policy-rc.d

mount -o bind /proc ${MNTROOTFS}/proc
mount -o bind /dev ${MNTROOTFS}/dev
mount -o bind /dev/pts ${MNTROOTFS}/dev/pts

# Enable the cross compiling environment in this chroot
#chroot ${MNTROOTFS} dpkg --add-architecture armhf

chroot ${MNTROOTFS} apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 5B2D0C5561707B09
chroot ${MNTROOTFS} apt-get -y update
chroot ${MNTROOTFS} apt-get -y upgrade
chroot ${MNTROOTFS} apt-get -y purge xen-utils-common xen-utils-4.4
chroot ${MNTROOTFS} apt-get -y autoremove
chroot ${MNTROOTFS} apt-get -y install openssh-server ocaml ocaml-findlib build-essential lvm2 aspcud pkg-config m4 libssl-dev libffi-dev parted avahi-daemon libnss-mdns iw batctl --no-install-recommends
chroot ${MNTROOTFS} apt-get -y install libxml2-dev libdevmapper-dev libpciaccess-dev libnl-dev libgnutls-dev --no-install-recommends
chroot ${MNTROOTFS} apt-get -y install tcpdump telnet nmap tshark tmux locate hping3 man-db --no-install-recommends
chroot ${MNTROOTFS} apt-get -y install uuid-dev software-properties-common libmysqlclient-dev bridge-utils --no-install-recommends

# Packages required to compile the xen-tools natively when the board boots
chroot ${MNTROOTFS} apt-get -y install libc6-dev:armhf libncurses-dev:armhf uuid-dev:armhf libglib2.0-dev:armhf libssl-dev:armhf libssl-dev:armhf libaio-dev:armhf libyajl-dev:armhf python gettext gcc git libpython2.7-dev:armhf libfdt-dev:armhf libpixman-1-dev --no-install-recommends

rm usr/sbin/policy-rc.d

echo UseDNS no >> etc/ssh/sshd_config

# Hostname
sed -i "s/linaro-developer/$BOARD/" etc/hosts
echo $BOARD > etc/hostname

# Allow Linux to fix filesystems if errors are found when it is trying to mount
# them
sed -i "s/#FSCKFIX=no/FSCKFIX=yes/" etc/default/rcS

# Fix some syslog deficiencies with the rsyslog daemon from the base FS.
sed -i "/\s+create_xconsole$/d" etc/init.d/rsyslog
sed -i "65,68s/^/#/" etc/rsyslog.d/50-default.conf
chroot ${MNTROOTFS} touch /var/log/syslog
chroot ${MNTROOTFS} chown syslog.adm /var/log/syslog

# Suppress the avahi-daemon messages
sed -i "5i# Discard avahi-daemon messages, they keep flooding the syslog\n:syslogtag, contains, \"avahi-daemon\" stop\n" etc/rsyslog.d/50-default.conf

# Build and install the custom xen tools, this has to be done here so that the
# tools are linking against the correct libraries, then install the new xen
# service.  The update-rc.d command must be run manually since we're building
# xen tools from source (normally this is done by a distribution-specific
# project).
chroot ${MNTROOTFS} /bin/bash -ex <<EOF

cd /usr/src/xen
CONFIG_SITE=/usr/src/xen/config.cache ./configure PYTHON_PREFIX_ARG=--install-layout=deb MINIOS_UPSTREAM_URL=https://github.com/talex5/mini-os.git MINIOS_UPSTREAM_REVISION=master --prefix=/usr --with-xenstored=oxenstored --enable-stubdom --enable-c-stubdom --build=x86_64-linux-gnu --host=arm-linux-gnueabihf
make dist-tools CROSS_COMPILE=arm-linux-gnueabihf- XEN_TARGET_ARM=arm32 MINIOS_UPSTREAM_URL=https://github.com/talex5/mini-os.git MINIOS_UPSTREAM_REVISION=master -j 4
make dist-stubdom CROSS_COMPILE=arm-linux-gnueabihf- XEN_TARGET_ARM=arm32 MINIOS_UPSTREAM_URL=https://github.com/talex5/mini-os.git MINIOS_UPSTREAM_REVISION=master -j 4
make install-tools CROSS_COMPILE=arm-linux-gnueabihf- XEN_TARGET_ARM=arm32 MINIOS_UPSTREAM_URL=https://github.com/talex5/mini-os.git MINIOS_UPSTREAM_REVISION=master
make install-stubdom CROSS_COMPILE=arm-linux-gnueabihf- XEN_TARGET_ARM=arm32 MINIOS_UPSTREAM_URL=https://github.com/talex5/mini-os.git MINIOS_UPSTREAM_REVISION=master

echo "Enabling new Xen services"
update-rc.d xencommons defaults 19 81
update-rc.d xendomains defaults 21 79
EOF

echo "deb http://ppa.launchpad.net/avsm/ocaml42+opam12/ubuntu trusty main" > ${MNTROOTFS}/etc/apt/sources.list.d/ppa-opam.list
chown root ${MNTROOTFS}/etc/apt/sources.list.d/ppa-opam.list
chroot ${MNTROOTFS} apt-get -y update
chroot ${MNTROOTFS} apt-get -y upgrade
chroot ${MNTROOTFS} apt-get -y install opam --no-install-recommends

# Mirage user
chroot ${MNTROOTFS} userdel -r linaro
chroot ${MNTROOTFS} useradd -s /bin/bash -G admin -m mirage -p mljnMhCVerQE6	# Password is "mirage"

# the resize application isn't on this image, so use a bash equivalent
chroot ${MNTROOTFS} cat >> home/mirage/.profile <<EOF

if [ -n "\$PS1" ]; then
    # bash equivalent of the "resize" command
    echo -en "\e[18t" # returns \e[8;??;??t
    IFS='[;'
    read -d t -s esc params
    set -- \$params
    [ \$# = 3 -a "\$1" = 8 ] && shift
    [ \$# != 2 ] && echo error >&2 && exit 1
    stty rows "\$1" cols "\$2"
fi
EOF

# OPAM init
OPAM_ROOT=/home/mirage/.opam
OPAM_REPO=/home/mirage/git/opam-repository
git clone https://github.com/ocaml/opam-repository.git ${MNTROOTFS}/${OPAM_REPO}
chroot ${MNTROOTFS} chown -R mirage ${OPAM_REPO}
chroot ${MNTROOTFS} opam init ${OPAM_REPO} -y --root=${OPAM_ROOT}

# opam install can fail occasionally when it is unable to download a package.  
# In that case it returns error 66 to the shell.  So allow up to 3 retries when 
# doing the "opam install" step.
#
# NOTE: the "opam repo add" command is run in the bash shell because for some 
# reason it doesn't correctly reference the ${OPAM_ROOT} path when executed with 
# "chroot ${MNTROOTFS} opam repo add..."
#
# Pin mirage to version 2.8.0 since later versions include a mirage-logs package
# that is troublesome.
chroot ${MNTROOTFS} /bin/bash -x <<EOF
export OPAMROOT=${OPAM_ROOT}
opam repo add mirage-xen-latest https://github.com/dornerworks/mirage-xen-latest-dev.git
opam update
status=1
for i in {1..3}; do
    timeout 600 opam pin add -y mirage 2.8.0
    status=\$?
    if [ \$status -eq 0 ]; then
        echo "opam pin \$i success"
        break
    elif [ \$status -eq 66 ]; then
        echo "opam package download failure \$i (\$status), retrying..."
    elif [ \$status -eq 124 ]; then
        echo "opam command timed out \$i (\$status), retrying..."
    else
        echo "opam pin failure \$i (\$status), exiting!"
        exit \$status
    fi
done
for i in {1..3}; do
    timeout 600 opam pin add -y mirage-bootvar-xen 0.3.1
    status=\$?
    if [ \$status -eq 0 ]; then
        echo "opam pin \$i success"
        break
    elif [ \$status -eq 66 ]; then
        echo "opam package download failure \$i (\$status), retrying..."
    elif [ \$status -eq 124 ]; then
        echo "opam command timed out \$i (\$status), retrying..."
    else
        echo "opam pin failure \$i (\$status), exiting!"
        exit \$status
    fi
done
for i in {1..3}; do
    timeout 600 opam install -y depext vchan mirage-console mirage-xen
    status=\$?
    if [ \$status -eq 0 ]; then
        echo "opam install \$i success"
        break
    elif [ \$status -eq 66 ]; then
        echo "opam package download failure \$i (\$status), retrying..."
    elif [ \$status -eq 124 ]; then
        echo "opam command timed out \$i (\$status), retrying..."
    else
        echo "opam install failure \$i (\$status), exiting!"
        exit \$status
    fi
done
exit \$status
EOF

# Ensure that the opam installed applications are in the path by default.
echo "eval \$(opam config env)" >> home/mirage/.bashrc

chroot ${MNTROOTFS} chown -R mirage /home/mirage
