#!/bin/sh -eux
# vi:shiftwidth=2

rm -rf linux-arm-modules
cd linux
make ARCH=arm zImage dtbs -j 4
make ARCH=arm modules -j 4
make ARCH=arm INSTALL_MOD_PATH="`pwd`/../linux-arm-modules" modules_install -j 4
cd ..

case $DISTROVER in
  trusty)
    # The depmod step in the kernel build seems to work fine
    ;;
  vivid)
    # kmod is not available on Travis CI
    sudo apt-get -y install kmod || true
    KERNELVER=`make -C linux ARCH=arm --no-print-directory kernelversion`
    depmod -b "`pwd`/linux-arm-modules" -F linux/System.map ${KERNELVER}
    ;;
  *)
    echo Unknown DISTROVER $DISTROVER
    exit 1
    ;;
esac
