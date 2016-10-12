#!/bin/sh

set -ex

ALPINEV=v3.4
TGZ=alpine-uboot-3.4.0-armhf.tar.gz
if [ ! -r $TGZ ]; then
    curl -LO http://dl-cdn.alpinelinux.org/alpine/$ALPINEV/releases/armhf/$TGZ
    curl -LO http://dl-cdn.alpinelinux.org/alpine/$ALPINEV/releases/armhf/$TGZ.asc
    gpg -v $TGZ.asc
fi

if [ ! -d u-boot ]; then
    git clone http://git.denx.de/u-boot.git
fi
cd u-boot && git checkout -f v2016.05 && cd ..

if [ ! -d linux ]; then
    git clone http://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/
    git remote add -f stable \
        https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
fi
cd linux && git checkout -f v4.4.14 && cd ..
