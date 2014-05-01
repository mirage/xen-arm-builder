#!/bin/sh -ex
# Clone github repos, and pull to refresh them if they exist

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

if [ ! -d linux-sunxi ]; then
  clone_branch git://github.com/linux-sunxi linux-sunxi sunxi-devel
else
  cd linux-sunxi
  git pull origin sunxi-devel
  cd ..
fi

if [ ! -d xen ]; then
  clone_branch git://xenbits.xen.org xen stable-4.4
else
  cd xen
  git pull origin stable-4.4
  cd ..
fi
