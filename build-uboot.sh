#!/bin/sh -ex

cd u-boot-sunxi
make CROSS_COMPILE=arm-linux-gnueabihf- Cubieboard2_config
make CROSS_COMPILE=arm-linux-gnueabihf- -j 4
