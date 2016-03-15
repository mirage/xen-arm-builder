#!/bin/sh -ex
# Clone github repos, and pull to refresh them if they exist

! grep "NAME=\"Debian" /etc/os-release > /dev/null
NOT_DEBIAN=$?

if [ $NOT_DEBIAN = 0 ]; then
    GCC=gcc-arm-linux-gnueabihf
else
    GCC=gcc-4.7-arm-linux-gnueabihf
fi

sudo apt-get -y install rsync git $GCC build-essential qemu kpartx binfmt-support qemu-user-static python bc parted dosfstools curl device-tree-compiler

clone_branch () {
  git clone ${1}/${2}.git
  cd $2
  if [ "$3" != "master" ]; then
    git checkout -b $3 origin/$3
  fi
  cd ..
}

if [ ! -d u-boot ]; then
  git clone git://git.denx.de/u-boot.git -b v2016.03
else
  cd u-boot
  git pull --ff-only origin v2016.03
  cd ..
fi

if [ ! -d linux ]; then
  git clone https://github.com/torvalds/linux.git -b v4.5
else
  cd linux
  git reset HEAD --hard
  git pull --ff-only https://github.com/torvalds/linux.git v4.5
  cd ..
fi

cd linux
for i in ../patches/linux*.patch; do
  if [ -e $i ]; then
    patch -p1 < $i
  fi
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
  clone_branch https://github.com/mirage xen stable-4.6
else
  cd xen
  git pull --ff-only https://github.com/mirage/xen.git stable-4.6
  cd ..
fi

cd xen
for i in ../patches/xen*.patch; do
  if [ -e $i ]; then
    patch -p1 < $i
  fi
done
cd ..

