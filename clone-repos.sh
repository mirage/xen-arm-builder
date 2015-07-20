#!/bin/sh -eux
# Clone github repos, and pull to refresh them if they exist
# vi:shiftwidth=2

if grep -q "NAME=\"Debian" /etc/os-release ; then
    GCC=gcc-4.7-arm-linux-gnueabihf
else
    GCC=gcc-arm-linux-gnueabihf
fi

sudo apt-get -y install rsync git $GCC build-essential kpartx binfmt-support python bc parted dosfstools
case $DISTROVER in
  trusty)
    sudo apt-get -y install qemu qemu-user-static
    LINUX_URL=https://github.com/talex5
    LINUX_BRANCH=master
    XEN_URL=https://github.com/talex5
    XEN_BRANCH=fix-grant-mapping
    APPLY_PATCHES=true
    ;;
  vivid)
    sudo apt-get -y install qemu-utils
    LINUX_URL=https://github.com/infidel
    LINUX_BRANCH=cubie-vivid
    # blktap2 patches don't compile yet with Linux 4.1
    APPLY_PATCHES=false
    ;;
esac

clone_branch () {
  git clone ${1}/${2}.git
  cd $2
  if [ "$3" != "master" ]; then
    git checkout -b $3 origin/$3
  fi
  cd ..
}

if [ ! -d u-boot ]; then
  git clone git://git.denx.de/u-boot.git -b v2015.04
else
  cd u-boot
  git pull --ff-only origin v2015.04
  cd ..
fi

if [ ! -d linux ]; then
  clone_branch ${LINUX_URL} linux ${LINUX_BRANCH}
else
  cd linux
  git reset HEAD --hard
  rm -rf drivers/block/blktap2 include/linux/blktap.h
  git pull --ff-only ${LINUX_URL}/linux.git ${LINUX_BRANCH}
  cd ..
fi

if $APPLY_PATCHES ; then
  cd linux
  for i in ../patches/linux*.patch
  do
    patch -p1 < $i
  done
  cd ..
fi

if [ ! -d linux-firmware ]; then
  clone_branch https://git.kernel.org/pub/scm/linux/kernel/git/firmware linux-firmware master
else
  cd linux-firmware
  git pull --ff-only https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git master
  cd ..
fi

if $BUILD_XEN ; then
  if [ ! -d xen ]; then
    clone_branch ${XEN_URL} xen ${XEN_BRANCH}
  else
    cd xen
    git pull --ff-only ${XEN_URL}/xen.git ${XEN_BRANCH}
    cd ..
  fi
fi

