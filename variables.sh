export V=${V-1}
export TARGET=${TARGET-Cubieboard2}

export TARGETlc=$(tr '[:upper:]' '[:lower:]' <<<"$TARGET")
export DTB=src/linux/arch/arm/boot/dts/${DTB-sun7i-a20-${TARGETlc}.dtb}

export ALPINEV=3.4.0
export ALPINETGZ=alpine-uboot-$ALPINEV-armhf.tar.gz

export SDSIZE=${SDSIZE-32G}
export UBOOTBIN=${UBOOTBIN-src/u-boot/u-boot-sunxi-with-spl.bin}
export ZIMAGE=${ZIMAGE-src/linux/arch/arm/boot/zImage}

echo "=== Configuration"
echo "TARGET=$TARGET"
echo "SDSIZE=$SDSIZE"
echo "V=$V"
echo
echo "DTB=$DTB"
echo "ALPINEV=$ALPINEV"
echo "UBOOTBIN=$UBOOTBIN"
echo "ZIMAGE=$ZIMAGE"
