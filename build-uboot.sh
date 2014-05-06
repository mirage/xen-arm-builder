#!/bin/sh -ex

case $BOARD in
cubieboard2) TARG=Cubieboard2_config ;;
cubietruck) TARG=Cubietruck_config ;;
*) echo Unknown board $BOARD;; exit 1
esac

cd u-boot-sunxi
make CROSS_COMPILE=arm-linux-gnueabihf- $TARG
make CROSS_COMPILE=arm-linux-gnueabihf- -j 4
