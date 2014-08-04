# SUNXI Xen Boot Script

# Addresses suitable for 1GB system, adjust as appropriate for a 2GB system.
# Top of RAM:         0x80000000
# Xen relocate addr   0x7fe00000
setenv kernel_addr_r  0xbf600000 # 8M
setenv ramdisk_addr_r 0xbee00000 # 8M
setenv fdt_addr       0xbec00000 # 2M
setenv xen_addr_r     0xbea00000 # 2M

setenv fdt_high      0xffffffff # Load fdt in place instead of relocating

# Load xen/xen to ${xen_addr_r}.
fatload mmc 0 ${xen_addr_r} /xen
setenv bootargs "console=dtuart dtuart=/soc@01c00000/serial@01c28000 dom0_mem=512M"

# Load appropriate .dtb file to ${fdt_addr}
fatload mmc 0 ${fdt_addr} /sun7i-a20-cubietruck.dtb
fdt addr ${fdt_addr} 0x40000
fdt resize
fdt chosen
fdt set /chosen \#address-cells <1>
fdt set /chosen \#size-cells <1>

# Load Linux arch/arm/boot/zImage to ${kernel_addr_r}
fatload mmc 0 ${kernel_addr_r} /vmlinuz

fdt mknod /chosen module@0
fdt set /chosen/module@0 compatible "xen,linux-zimage" "xen,multiboot-module"
fdt set /chosen/module@0 reg <${kernel_addr_r} 0x${filesize} >
fdt set /chosen/module@0 bootargs "console=hvc0 ro root=/dev/mmcblk0p2 rootwait clk_ignore_unused"

bootz ${xen_addr_r} - ${fdt_addr}
