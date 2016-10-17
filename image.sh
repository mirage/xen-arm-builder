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

fdisk sdcard.img <<__EOF
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
__EOF

losetup -D && LOFS=$(losetup -f --show -o$((2048*512)) sdcard.img)
mkfs.vfat $LOFS

mount $LOFS /mnt
tar -C /mnt -xaf src/$ALPINETGZ
cp $ZIMAGE /mnt/boot/vmlinuz
cp $DTB /mnt/boot
cp src/u-boot/boot.scr /mnt
dd of=/mnt/extlinux/extlinux.conf <<__EOF
  LABEL custom
    MENU LABEL Custom kernel
    LINUX /boot/vmlinuz
    INITRD /boot/initramfs-grsec
    DEVICETREEDIR /boot
    APPEND modules=loop,squashfs,sd-mod,usb-storage console=\${console}
__EOF
umount /mnt

dd if=$UBOOTBIN of=sdcard.img bs=1024 seek=8 conv=notrunc
