#!/bin/sh

source ./variables.sh

if [ \! -s "$UBOOTBIN" ]; then
    echo "U-Boot binary $UBOOTBIN not found; 'make prepare' perhaps?"
    exit 1
elif [ \! -s "$ZIMAGE" ]; then
    echo "Linux kernel image $ZIMAGE not found; 'make prepare' perhaps?"
    exit 2
elif [ \! -s "$DTB" ]; then
    echo "DTB $DTB not found; 'make prepare' perhaps?"
    exit 3
elif [ \! -s "src/$ALPINETGZ" ]; then
    echo "Alpine tarball src/$ALPINETGZ not found; 'make prepare' perhaps?"
    exit 3
fi

set -ex

dd if=/dev/zero of=sdcard.img bs=1 count=0 seek=$SDSIZE

fdisk sdcard.img <<EOF
o
n
p
1

+128M
t
6
n
p
2


t
2
8e
w
EOF

losetup -D && LOFS=$(losetup -f --show -o$((2048*512)) sdcard.img)
mkfs.vfat $LOFS

mount $LOFS /mnt
tar -C /mnt -xaf src/$ALPINETGZ

cp $ZIMAGE /mnt/boot/vmlinuz
cp $DTB /mnt/boot
cp src/u-boot/boot.scr /mnt

cat >/mnt/extlinux/extlinux.conf <<EOF
  LABEL custom
    MENU LABEL Custom kernel
    LINUX /boot/vmlinuz
    INITRD /boot/initramfs-grsec
    DEVICETREEDIR /boot
    APPEND modules=loop,squashfs,sd-mod,usb-storage console=\${console}
EOF

cat >/mnt/alpine-dom0-install.sh <<EOF
#!/bin/sh

set -ex

# upgrade packages
apk -U upgrade && lbu ci

# configure networking
apk add -uU avahi dbus
echo net.ipv4.igmp_max_memberships=20 > /etc/sysctl.conf
service sysctl restart
for s in dbus avahi-daemon ; do service \$s start && rc-update add \$s ; done

# set current time
chronyc makestep

# enable password login over SSH
sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/^#PermitEmptyPasswords no/PermitEmptyPasswords yes/' /etc/ssh/sshd_config
service sshd restart

# configure bridged networking
apk add -uU bridge
HN=\$(hostname)
cat >/etc/network/interfaces <<_EOF
auto lo
iface lo inet loopback

auto br0
iface br0 inet dhcp
    hostname \$HN
    bridge-ports eth0
    bridge-stp 0

auto eth0
iface eth0 inet dhcp
    hostname \$HN
_EOF

# install Xen
sed -i -e 's,^\#\(.*/edge/main\)$,\1,g\' /etc/apk/repositories
apk update
apk add xen xen-hypervisor

# add Xen into boot
mount -o remount,rw /media/mmcblk0p1/
cp /boot/xen /media/mmcblk0p1/boot/xen
cat >/media/mmcblk0p1/extlinux/extlinux.conf <<_EOF
LABEL local
  MENU LABEL Local boot
  LOCALBOOT 0
LABEL custom
  MENU LABEL Custom kernel
  LINUX /boot/vmlinuz
  INITRD /boot/initramfs-grsec
  DEVICETREEDIR /boot
  APPEND modules=loop,squashfs,sd-mod,usb-storage console=\${console}
_EOF
mount -o remount,ro /media/mmcblk0p1/

# install and configure LVM, kpartx
apk add -uU lvm2 multipath-tools
service lvm start
rc-update add lvm

# create LVM volume group
pvcreate /dev/mmcblk0p2
VG=\$HN
vgcreate \$VG /dev/mmcblk0p2

# create Alpine domU configuration
cat >/etc/xen/alpine.cfg <<_EOF
name = "alpine"
kernel = "/media/mmcblk0p1/boot/vmlinuz"
ramdisk = "/media/mmcblk0p1/boot/initramfs-grsec"
cmdline = "console=hvc0"
memory = 128
vif = ["mac=06:ac:b4:92:fc:49,bridge=br0"]
disk = ["vdev=xvda,format=raw,target=/dev/@HOSTNAME@/alpine-disk"]
_EOF
sed -i "s/@HOSTNAME@/\$HN/g" /etc/xen/alpine.cfg

# create Debian domU configuration
cat > /etc/xen/debian.cfg <<_EOF
name = "debian"

memory = 256
vcpus = 2

disk = ['phy:/dev/@HOSTNAME@/debian-disk,xvda,w']

vif = ['mac=02:ff:e4:2a:dc:1b,bridge=br0']

kernel = "/media/mmcblk0p1/boot/vmlinuz"
extra = "console=hvc0 xencons=tty root=/dev/xvda"
_EOF
sed -i "s/@HOSTNAME@/$(hostname)/g" /etc/xen/debian.cfg

# commit changes, reboot
lbu ci
reboot
EOF
chmod +x /mnt/alpine-dom0-install.sh

cat >/mnt/alpine-domU-install.sh <<EOF
#!/bin/sh

set -ex

# create and partition the Alpine domU volume group
VG=\$(hostname)
lvcreate -n alpine-disk -L 1G /dev/\$VG
( fdisk /dev/\$VG/alpine-disk || true ) <<_EOF
n
p
1

+128M
t
6
n
p
2


t
2
83
w
_EOF

kpartx -a /dev/\$VG/alpine-disk
dmsetup mknodes # Should be automatic, not sure why not

# format the volume gruop
FSDEV=/dev/mapper/\${VG//-/--}-alpine--disk1
mkfs.vfat \$FSDEV

# copy in the APK cache
mount \$FSDEV /mnt/
cp -r /media/mmcblk0p1/apks /mnt/apks
umount /mnt

# unmount and commit changes
kpartx -d /dev/\$VG/alpine-disk
dmsetup mknodes # Should be automatic, not sure why not
lbu ci
EOF
chmod +x /mnt/alpine-domU-install.sh

cat >/mnt/debian-domU-install.sh <<EOF
#!/bin/sh

set -ex

# setup the partition
VG=\$(hostname)
lvcreate -n debian-disk -L 8G /dev/\$VG
apk add -uU e2fsprogs
/sbin/mkfs.ext4 /dev/\$VG/debian-disk

# install debootstrap and build guest partition
apk -v cache clean
apk add -uU debootstrap perl
mount /dev/\$VG/debian-disk /mnt
debootstrap --verbose --arch armhf stretch /mnt
rm /mnt/initrd.gz /mnt/vmlinuz

# build missing configuration
chroot /mnt bash

HN=$(hostname)
echo "debian-\$HN" > /etc/hostname

PW=ucn
passwd -d root && echo -e "\$PW\n\$PW" | (passwd root)

cat >/etc/network/interfaces <<_EOF
auto eth0
allow-hotplug eth0
iface eth0 inet dhcp
_EOF

cat >/etc/fstab <<_EOF
/dev/xvda / ext4 defaults 1 1
_EOF

exit
umount /mnt
EOF
chmod +x /mnt/debian-domU-install.sh

umount /mnt

dd if=$UBOOTBIN of=sdcard.img bs=1024 seek=8 conv=notrunc
