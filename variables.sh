export TARGET=${TARGET-Cubieboard2}
export DTB=src/linux/arch/arm/boot/dts/${DTB-sun7i-a20-$TARGET.dtb}

export ALPINEV=3.4.0
export ALPINETGZ=alpine-uboot-$ALPINEV-armhf.tar.gz

export SDSIZE=${SDSIZE-32G}
export UBOOTBIN=${UBOOTBIN-src/u-boot/u-boot-sunxi-with-spl.bin}
export ZIMAGE=${ZIMAGE-src/linux/arch/arm/boot/zImage}
