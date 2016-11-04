# Building Cubieboard (ARM) Images

Based on <https://gist.github.com/ijc25/612b8b7975e9461c3584b1402df2cb34> by
Ian Campbell (@ijc25).

## Building Base Image

To create the builder, clone repos, build `u-boot` and `Linux`, and construct
disk image:

```
git clone https://github.com/mor1/arm-image-builder.git
cd arm-image-builder

make prepare # clones repos, pulls tarballs
make build   # use the Docker image to build the `linux/` and `u-boot/` trees
make image   # finally, create the on-disk `sdcard.img`
# ...or `make all`
```

By default `TARGET=Cubieboard2`; prefix each command above with
`TARGET=Cubietruck` to build for that. Other targets are available but have not
been tested.

Then, on OSX, to push the created `sdcard.img` to a physically mounted SD card:

```
make sdcard # ...runs `find-mnt` target to determine, on OSX, SD card mountpoint
```

After creating the SD card with the base image, you need to insert it into the
device, power on, and complete the installation.

## First Boot / (Re-)Initialisation

First, choose a new MAC address for the board. You can
use [randmac](https://www.hellion.org.uk/cgi-bin/randmac.pl) to generate a valid
local MAC address.

Then, insert SD card into the Cubie, attach serial dongle (or screen and
keyboard) and boot. Press any key to interrupt boot and (re-)initialise
environment (replace `xx:xx:xx:xx:xx:xx` with the MAC address generated above)
with:

    => env default -f -a
    ## Resetting to default environment
    => setenv ethaddr "xx:xx:xx:xx:xx:xx"
    => setenv localcmd run scan_dev_for_scripts
    => saveenv
    Saving Environment to MMC...
    Writing to MMC(0)... done
    => reset

## Base Install

After Alpine boots, login (`root`, no passwd) and setup:

```
setup-alpine
```

Configure the desired keyboard layout, locale, hostname, and so on; the defaults
for most things are fine. This will store config in `mmcblk0p1`, the FAT
partition that was created during `make image`.

When complete, upgrade packages, setup networking, and enable `root` login over
`ssh` by running:

```
/media/mmcblk0p1/alpine-dom0-install.sh
```

Note that this will reboot at this end, but Xen hasn't yet been configured.
After rebooting into Alpine, configure `dom0`:

```
setup-xen-dom0
ifconfig br0 promisc
lbu ci
```

You should now have an SD card that will boot your device into an Alpine Linux
dom0 on Xen. Access via `ssh` should also work so switch from serial to `ssh
root@$HOSTNAME.local`. To configure passwordless login using keys, login and
then:

```
mkdir -m 0700 /root/.ssh
cat >>/root/.ssh/authorized_keys <<EOF
ssh-rsa YOUR-SSH-PUBLIC-KEY-HERE
EOF
chmod 600 /root/.ssh/authorized_keys
lbu include /root/.ssh/authorized_keys
lbu ci
```

## Building Xen Guests

### Alpine

Create the guest partition, and then boot the `domU` in the usual way:

```
/media/mmcblk0p1/alpine-domU-install.sh
xl create -c /etc/xen/alpine.cfg
```

Finally, configure as usual by running `setup-alpine` in the domU.

### Debian

Similarly, create the guest partition, and then boot the domU in the usual way:

```
/media/mmcblk0p1/debian-domU-install.sh
xl create -c /etc/xen/debian.cfg
```
