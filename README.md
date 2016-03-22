The scripts in this repository provide an easy way to set up Xen on a Cubieboard 2 or CubieTruck with:

* U-Boot as the bootloader,
* Xen as the hypervisor,
* Ubuntu Trusty as dom0, and
* LVM managing guest disks.

# Pre-built binaries

To save time and the need to install Ubuntu, you can download pre-built SDcard images from here:

* http://blobs.openmirage.org/cubieboard2.tar (Cubieboard 2)
* http://blobs.openmirage.org/cubietruck.tar (CubieTruck)

# Building from source

These scripts must be run on Ubuntu or Debian (they install some
packages using `apt-get`).

1. Select your board (`cubieboard2` or `cubietruck`):

         $ export BOARD=cubieboard2

2. On Debian, follow the [sunxi](http://linux-sunxi.org/Toolchain)
toolchain instructions to install the **emdebian-archive-keyring**
package and the emdebian.org apt source.

   Note: Currently, the debian/ubuntu cross-compiler installed is gcc version
         4.8 which fails to compile the Linux and Xen kernels correctly.
         Instead it is recommended to go directly to
         [linaro](http://www.linaro.org/downloads/) and download the latest
         Linux little-endian compiler.  The
         gcc-linaro-5.1-2015.08-x86_64_arm-linux-gnueabihf version has been
         verified to work correctly.

3. Download the dependencies (this will clone all the relevant repositories):

         $ make clone

4. On Debian, symlink the GCC 4.7 cross-compilers into your `$PATH` as
described on the [sunxi](http://linux-sunxi.org/Toolchain) site.

5. Build U-Boot, Xen and Linux:

         $ make build

    You may get prompted about extra configuration options at this point.
    You can probably just press Return to accept the default for each one.

6. Build the SDcard image:

         $ make $BOARD.img

   It will need to mount various loopback devices on `/mnt` during this process.

# Installation

## Linux

1. Copy the `BOARD.img` to the SDcard, e.g.

        $ dd if=cubieboard2.img of=/dev/mmcblk0

## OS X

1. Find the disk device of the card you inserted:

        sudo diskutil list

   (e.g. `disk2`)

2. Unmount the disk images:

        sudo diskutil unmountDisk /dev/diskN

3. Copy the image:

        sudo dd if=cubieboard2.img of=/dev/rdiskN bs=64k

   Note: Without the 'rdisk' in the output file, the copying will be extremely slow due to buffering.

# Booting

Insert the SDcard in the device, then connect the network and power.
The device should get an IP address using DHCP.
SSH to the device (the name is `$BOARD.local.`, which can be used if your machine
supports mDNS/avahi/zeroconf):

    $ ssh mirage@cubieboard2.local.

The password is `mirage`.

Install your SSH public key and change login password (or lock the
account with `sudo passwd -l mirage`).

If you plan on connecting to TLS-secured services, don't forget to set
the system time so that certificate validity windows work correctly (not
many TLS certificates were valid in 1970).

# Using Xen

You should now be able to use Xen via the `xl` command:

    $ xl list
    Name                                        ID   Mem VCPUs      State   Time(s)
    Domain-0                                     0   512     2     r-----     171.7

# Adding device drivers

To add drivers to the supplied Linux kernel, first clone and install the default configuration:

	$ make clone

After cloning, the Linux kernel is in a folder called 'linux' and the default configuration file from the 'config/' folder has been copied to 'linux/.config'.

You can now configure the kernel, for example by using menuconfig:

	$ cd linux
	$ make clean
	$ make menuconfig

When you are happy with the configuration you may copy 'linux/.config' back to 'config/' to make sure that it is not overwritten later by 'make clone'.

If the drivers you have enabled need binary firmware, add the name of the firmware file (or folder) to the FIRMWARE-variable in the Makefile. Alternatively, you can set the FIRMWARE environment variable before calling 'make':

	$ export FIRMWARE=rtlwifi

The specified firmware will be copied from 'linux-firmware/' to '/lib/firmware' on the final image.

You should now be able to build the new image with the updated kernel and firmware with "make build" and "make $BOARD.img".
