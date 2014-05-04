#!/bin/sh -ex
# Build a Xen/Ubuntu image for a Cubieboard2

# sudo apt-get install kpartx sfdisk curl
IMG=cubie.img
rm -f $IMG
qemu-img create $IMG 2G
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
dd if=/dev/zero of=${LOOPDEV} bs=1024 count=1024
dd if=u-boot-sunxi/u-boot-sunxi-with-spl.bin of=${LOOPDEV} bs=1024 seek=8
SIZE=`fdisk -l ${LOOPDEV} | grep Disk | grep bytes | awk '{print $5}'`
CYLINDERS=`echo $SIZE/255/63/512 | bc`
{
echo 1,16,0x0C,*
echo 17,,,-
} | sfdisk -D -H 255 -S 63 -C ${CYLINDERS} ${LOOPDEV}

WRKDIR=`pwd`

finish () {
  cd ${WRKDIR}
  umount /mnt/proc || true
  umount /mnt/dev || true
  umount /mnt || true
  kpartx -d ${LOOPDEV} || true
  losetup -d ${LOOPDEV} || true
}

trap finish EXIT

MLOOPDEV=`echo $LOOPDEV | sed -e 's,/dev/,/dev/mapper/,g'`
kpartx -a ${LOOPDEV}
mkfs.vfat ${MLOOPDEV}p1
mkfs.ext4 ${MLOOPDEV}p2

mount ${MLOOPDEV}p1 /mnt
cp boot/boot.scr /mnt/
cp linux-sunxi/arch/arm/boot/zImage /mnt/vmlinuz
cp linux-sunxi/arch/arm/boot/dts/sun7i-a20-cubieboard2.dtb /mnt/
cp xen/xen/xen /mnt/
umount /mnt

mount ${MLOOPDEV}p2 /mnt
tar -C /mnt -xf $ROOTFS
cd /mnt
mv binary/* .
rmdir binary
cp ${WRKDIR}/templates/fstab etc/fstab
cp ${WRKDIR}/templates/interfaces etc/network/interfaces
rm -f etc/resolv.conf
cp ${WRKDIR}/templates/resolv.conf etc/resolv.conf
cp ${WRKDIR}/templates/hvc0.conf etc/init
mount -o bind /proc /mnt/proc
mount -o bind /dev /mnt/dev
chroot /mnt apt-get -y update
chroot /mnt apt-get -y install openssh-server ocaml ocaml-native-compilers camlp4-extra opam build-essential
