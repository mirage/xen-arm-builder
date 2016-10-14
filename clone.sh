#!/bin/sh

source variables.sh

set -ex

mkdir -p src
cd src

if [ ! -r $TGZ ]; then
    S=dl-cdn.alpinelinux.org
    curl -LO http://$S/alpine/v${ALPINEV%.*}/releases/armhf/$ALPINETGZ
    curl -LO http://$S/alpine/v$${ALPINEV%.*}/releases/armhf/$ALPINETGZ.asc
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
