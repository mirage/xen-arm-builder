#!/bin/bash

# This scripts creates a guest partition and bootstraps it with Ubuntu. Must be run as root in dom0 on the host.
# Originally based on instructions from http://openmirage.org/wiki/xen-on-cubieboard2

# Exit on unset variables, errors
set -uo errexit

echo "Creating guest partition..."
lvcreate -L 4G vg0 --name linux-guest-1
/sbin/mkfs.ext4 /dev/vg0/linux-guest-1

echo "Bootstrapping..."
mount /dev/vg0/linux-guest-1 /mnt && \
trap "umount /mnt" EXIT # umount on exit

debootstrap --arch armhf trusty /mnt

echo "Setting hostname..."
echo "linux-guest-1" > /mnt/etc/hostname

echo "Configuring networking to use DHCP..."
echo 'auto eth0
iface eth0 inet dhcp' > /mnt/etc/network/interfaces

echo "Adding mirage user"
chroot /mnt useradd -s /bin/bash -G sudo -m mirage -p mljnMhCVerQE6	# Password is "mirage"
chroot /mnt passwd root -l # lock root user

echo "Setting up fstab"
echo "/dev/xvda       / ext4   rw,norelatime,nodiratime       0 1" > /mnt/etc/fstab

echo "Installing ssh and avahi..."
chroot /mnt apt-get install -y openssh-server avahi-daemon
echo "UseDNS no" >> /mnt/etc/ssh/sshd_config


echo "Creating linux-guest-1.conf..."
echo 'kernel = "/root/dom0_kernel"
memory = 256
name = "linux-guest-1"
vcpus = 2
serial="pty"
disk = [ "phy:/dev/vg0/linux-guest-1,xvda,w" ]
vif = ["bridge=xenbr0"]
extra = "console=hvc0 xencons=tty root=/dev/xvda"' > linux-guest-1.conf

echo "Done!"
echo "Start and attach to guest with"
echo -e "\txl create linux-guest-1.conf"
echo
echo "Connect to the guest with"
echo -e "\tssh mirage@linux-guest-1.local"
