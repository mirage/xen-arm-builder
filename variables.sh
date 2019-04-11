export TARGET=${TARGET-Cubieboard2}
export SDSIZE=${SDSIZE-32G}
export V=${V-1}
export J=${J-12}

export TARGETlc=$(tr '[:upper:]' '[:lower:]' <<<"$TARGET")
export DTB=src/linux-stable/arch/arm/boot/dts/${DTB-sun7i-a20-${TARGETlc}.dtb}

export ALPINEV=3.9.3
export ALPINETGZ=alpine-uboot-$ALPINEV-armhf.tar.gz

export UBOOTBIN=${UBOOTBIN-src/u-boot/u-boot-sunxi-with-spl.bin}
export ZIMAGE=${ZIMAGE-src/linux-stable/arch/arm/boot/zImage}

echo "=== Configuration"
echo "TARGET=$TARGET"
echo "SDSIZE=$SDSIZE"
echo "V=$V"
echo "J=$J"
echo
echo "DTB=$DTB"
echo "ALPINEV=$ALPINEV"
echo "ALPINETGZ=$ALPINETGZ"
echo "UBOOTBIN=$UBOOTBIN"
echo "ZIMAGE=$ZIMAGE"
echo "==="
