#!/bin/sh -ex

cd linux-sunxi
make ARCH=arm zImage dtbs -j 4
