#!/bin/sh -ex

cd xen
make dist-xen debug=y XEN_TARGET_ARCH=arm32 CROSS_COMPILE=arm-linux-gnueabihf- CONFIG_EARLY_PRINTK=sun7i -j4
