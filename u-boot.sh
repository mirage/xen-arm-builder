#!/bin/sh

set -ex

cd u-boot
make CROSS_COMPILE=arm-linux-gnueabi- Cubieboard2_defconfig
make CROSS_COMPILE=arm-linux-gnueabi- -j12

cat > boot.uscr <<"EOF"
setenv xen_addr_r 0x42e00000
load mmc 0 ${xen_addr_r} /boot/xen
load mmc 0 ${fdt_addr_r} /boot/${fdtfile}
load mmc 0 ${kernel_addr_r} /boot/vmlinuz

fdt addr ${fdt_addr_r}
fdt resize

fdt set /chosen \#address-cells <1>
fdt set /chosen \#size-cells <1>

fdt mknod /chosen module@0
fdt set /chosen/module@0 compatible "xen,linux-zimage" "xen,multiboot-module"
fdt set /chosen/module@0 reg <${kernel_addr_r} 0x${filesize} >
fdt set /chosen/module@0 bootargs "modules=loop,squashfs,sd-mod,usb-storage console=hvc0 clk_ignore_unused rootflags=size=128M"
fdt set /chosen xen,xen-bootargs "conswitch=x dom0_mem=256M"

load mmc 0 ${ramdisk_addr_r} /boot/initramfs-grsec
bootz ${xen_addr_r} ${ramdisk_addr_r}:${filesize} ${fdt_addr_r}
EOF

mkimage -T script -A arm -d boot.uscr boot.scr
