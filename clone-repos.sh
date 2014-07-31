#!/bin/sh -ex
# Clone github repos, and pull to refresh them if they exist

sudo apt-get -y install rsync git gcc-arm-linux-gnueabihf build-essential qemu kpartx binfmt-support qemu-user-static python bc parted dosfstools

clone_branch () {
  git clone ${1}/${2}.git
  cd $2
  if [ "$3" != "master" ]; then
    git checkout -b $3 origin/$3
  fi
  cd ..
}

if [ ! -d u-boot-sunxi ]; then
  clone_branch git://github.com/jwrdegoede u-boot-sunxi sunxi-next
else
  cd u-boot-sunxi
  git pull origin sunxi-next
  cd ..
fi

if [ ! -d linux ]; then
  clone_branch git://git.kernel.org/pub/scm/linux/kernel/git/torvalds linux master
  git reset --hard v3.16-rc7
else
  cd linux
  git pull origin v3.16-rc7
  cd ..
fi

if [ ! -d xen ]; then
  clone_branch git://xenbits.xen.org xen stable-4.4
else
  cd xen
  git pull origin stable-4.4
  cd ..
fi
