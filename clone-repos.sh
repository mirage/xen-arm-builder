#!/bin/sh -ex
# Clone github repos, and pull to refresh them if they exist

! grep "NAME=\"Debian" /etc/os-release > /dev/null
NOT_DEBIAN=$?

if [ $NOT_DEBIAN = 0 ]; then
    GCC=gcc-arm-linux-gnueabihf
else
    GCC=gcc-4.7-arm-linux-gnueabihf
fi

# Only attempt to install a compiler if one isn't found
! which arm-linux-gnueabihf-gcc > /dev/null
GCC_FOUND=$?
if [ $GCC_FOUND = 0 ]; then
    sudo apt-get -y install rsync git $GCC build-essential qemu kpartx binfmt-support qemu-user-static python bc parted dosfstools curl device-tree-compiler libncurses5-dev
else
    sudo apt-get -y install rsync git build-essential qemu kpartx binfmt-support qemu-user-static python bc parted dosfstools curl device-tree-compiler libncurses5-dev
fi

# Clones or updates git repos depending on if they already exist or not.
# ex: clone_branch <dir> <branch or tag> <repo_url>
clone_branch () {
  if [ ! -d ${1} ]; then
    git clone --depth 1 -b ${2} ${3} ${1} || echo "git failed with status: $?"
  else
    cd $1
    git reset HEAD --hard
    git pull --ff-only ${3} ${2} || echo "git failed with status: $?"
    cd ..
  fi
}

clone_branch u-boot v2016.03 git://git.denx.de/u-boot.git

clone_branch linux linux-4.5.y git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git

cd linux
for i in ../patches/linux*.patch; do
  if [ -e $i ]; then
    patch -p1 < $i
  fi
done
cd ..

clone_branch linux-firmware master https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git

clone_branch xen stable-4.7 git://xenbits.xen.org/xen.git

cd xen
for i in ../patches/xen*.patch; do
  if [ -e $i ]; then
    patch -p1 < $i
  fi
done
cd ..
