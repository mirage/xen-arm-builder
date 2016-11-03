#!/bin/sh

source variables.sh

set -ex

mkdir -p src
cd src

if [ ! -r $ALPINETGZ ]; then
    S=dl-cdn.alpinelinux.org
    curl -LO http://$S/alpine/v${ALPINEV%.*}/releases/armhf/$ALPINETGZ
    curl -LO http://$S/alpine/v$${ALPINEV%.*}/releases/armhf/$ALPINETGZ.asc
    cat $ALPINETGZ.asc
    gpg -v $ALPINETGZ.asc
fi

# clone u-boot
if [ ! -d u-boot ]; then
    git clone http://git.denx.de/u-boot.git
fi
cd u-boot && git checkout -f v2016.05 && cd ..

# clone linux
if [ ! -d linux-stable ]; then
    git clone \
        https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
fi
cd linux-stable && git checkout -f v4.4.14 && cd ..
