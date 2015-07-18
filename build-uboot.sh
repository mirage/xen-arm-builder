#!/bin/sh -eux

sudo apt-get install -y device-tree-compiler

case $BOARD in
cubieboard2) TARG=Cubieboard2_config ;;
cubietruck) TARG=Cubietruck_config ;;
*) echo Unknown board $BOARD; exit 1;;
esac

cd u-boot
BUILD_DIR=$(pwd)/build-$BOARD
make O=$BUILD_DIR CROSS_COMPILE=arm-linux-gnueabihf- $TARG
make O=$BUILD_DIR CROSS_COMPILE=arm-linux-gnueabihf- -j 4
