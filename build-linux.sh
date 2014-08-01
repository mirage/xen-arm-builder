#!/bin/sh -ex

rm -rf linux-arm-modules
cd linux
make ARCH=arm zImage dtbs -j 4
make ARCH=arm modules -j 4
make ARCH=arm INSTALL_MOD_PATH="`pwd`/../linux-arm-modules" modules_install -j 4
