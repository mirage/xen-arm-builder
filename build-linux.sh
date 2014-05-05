#!/bin/sh -ex

rm -rf linux-arm-modules
cd linux-sunxi
make ARCH=arm zImage dtbs -j 4
make ARCH=arm INSTALL_MOD_PATH="`pwd`/../linux-arm-modules" modules modules_install -j 4
