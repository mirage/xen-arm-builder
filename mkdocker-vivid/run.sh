#!/bin/sh
if [ ! -d .git ] ; then
    echo This script needs to run from the repository root
    exit 1
fi
# Note that hyphens aren't allowed in variable names, and underscores aren't allowed in hostnames
docker run --rm -e "http_proxy=http://proxy:3142/" -e DISTROVER=vivid --link apt-cacher:proxy --privileged -it -v `pwd`:/xen-arm-builder -w /xen-arm-builder xen-sdcard-builder-vivid
