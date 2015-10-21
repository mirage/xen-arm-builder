#!/bin/sh -ex
# Clone github repos, and pull to refresh them if they exist

! grep "NAME=\"Debian" /etc/os-release > /dev/null
NOT_DEBIAN=$?

if [ $NOT_DEBIAN = 0 ]; then
    GCC=gcc-arm-linux-gnueabihf
else
    GCC=gcc-4.7-arm-linux-gnueabihf
fi

sudo apt-get -y install rsync git $GCC build-essential qemu kpartx binfmt-support qemu-user-static python bc parted dosfstools

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
  #clone_branch git://git.kernel.org/pub/scm/linux/kernel/git/torvalds linux master
  clone_branch https://github.com/talex5 linux master
else
  cd linux
  git reset HEAD --hard
  rm -rf drivers/block/blktap2 include/linux/blktap.h
  git pull --ff-only https://github.com/talex5/linux.git master
  cd ..
fi

cd linux
for i in ../patches/linux*.patch
do
  patch -p1 < $i
done
cd ..

if [ ! -d linux-firmware ]; then
  clone_branch https://git.kernel.org/pub/scm/linux/kernel/git/firmware linux-firmware master
else
  cd linux-firmware
  git pull --ff-only https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git master
  cd ..
fi

if [ ! -d xen ]; then
  #clone_branch git://xenbits.xen.org xen stable-4.4
  clone_branch https://github.com/talex5 xen fix-grant-mapping
else
  cd xen
  #git pull origin stable-4.4
  git pull --ff-only https://github.com/talex5/xen.git fix-grant-mapping
  cd ..
fi

cd xen
for i in ../patches/xen*.patch
do
  patch -p1 < $i
done
cd ..

