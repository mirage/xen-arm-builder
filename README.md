The scripts in this repository provide an easy way to set up Xen on a Cubieboard 2 or CubieTruck with:

* U-Boot as the bootloader,
* Xen as the hypervisor,
* Ubuntu Trusty as dom0, and
* LVM managing guest disks.

These scripts must be run on Ubuntu (they install some packages using `apt-get`).

# Pre-built binaries

To save time, you can download pre-build images from here:

* http://blobs.openmirage.org/cubieboard2-xen-iso.tar.bz2 (Cubieboard 2)
* http://blobs.openmirage.org/cubietruck-xen-iso.tar.bz2 (CubieTruck)

# Building from source

1. Select your board (`cubieboard2` or `cubietruck`):

         $ export BOARD=cubieboard2

2. Download the dependencies (this will clone all the relevant repositories):

         $ make clone

3. Build U-Boot, Xen and Linux:

         $ make build

    You may get prompted about extra configuration options at this point.
    You can probably just press Return to accept the default for each one.

4. Build the SDcard image:

         $ make cubie.img

   It will need to mount various loopback devices on `/mnt` during this process.

# Installation

1. Copy the `cubie.img` to the SDcard:

        $ dd if=cubie.img of=/dev/mmcblk0

2. Insert the SDcard in the device, then connect the network and power.
   The device should get an IP address using DHCP.
   SSH to the device as user `linaro` (password `linaro`), install your SSH public key and
   change login password (or lock the account with `sudo passwd -l linaro`).

# Guest disks

The default image has an LVM partition on `mmcblk0p3`, but it's quite small so you may prefer to delete it and create a new one that fills the disk.
You can use `cfdisk` for this, then use `vgcreate` to create a volume group from the new partition:

    root@cubieboard2:~# lsblk
    NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
    mmcblk0     179:0    0  14.7G  0 disk
    ├─mmcblk0p1 179:1    0   128M  0 part
    ├─mmcblk0p2 179:2    0     3G  0 part /
    └─mmcblk0p3 179:3    0  11.5G  0 part
    
    root@cubieboard2:~# vgcreate vg0 /dev/mmcblk0p3
      No physical volume label read from /dev/mmcblk0p3
      Physical volume "/dev/mmcblk0p3" successfully created
      Volume group "vg0" successfully created

# Using Xen

You should now be able to use Xen via the `xl` command:

    $ xl list
    Name                                        ID   Mem VCPUs      State   Time(s)
    Domain-0                                     0   512     2     r-----     171.7
