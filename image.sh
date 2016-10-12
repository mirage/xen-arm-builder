#!/bin/sh

set -ex

export IMAGE=cubieboard2.img

dd if=/dev/zero of=$IMAGE bs=1 count=0 seek=512M status=progress

fdisk $IMAGE <<__EOF
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

losetup -D && losetup -f -o$((2048*512)) $IMAGE
mkfs.vfat /dev/loop/0
mount /dev/loop/0 /mnt

tar -C /mnt -xaf alpine-uboot-3.4.0-armhf.tar.gz
cp linux/arch/arm/boot/zImage /mnt/boot/vmlinuz
cp linux/arch/arm/boot/dts/sun7i-a20-cubieboard2.dtb /mnt/boot
dd of=/mnt/extlinux/extlinux.conf <<__EOF
  LABEL custom
    MENU LABEL Custom kernel
    LINUX /boot/vmlinuz
    INITRD /boot/initramfs-grsec
    DEVICETREEDIR /boot
    APPEND modules=loop,squashfs,sd-mod,usb-storage console=\${console}
__EOF
umount /mnt

dd if=u-boot/u-boot-sunxi-with-spl.bin of=cubieboard2.img \
   bs=1024 seek=8 conv=notrunc
