# Based on the SUNXI Xen Boot Script

# Addresses suitable for 2GB system

# Top of RAM:         0xc0000000
# Xen relocate addr   0xbfe00000

setenv fdt_addr       0xaec00000 # 2M
setenv fdt_high       0xffffffff # Load fdt in place instead of relocating

# Put Xen and Linux in the top half of RAM, or you get
# "Failed to allocate contiguous memory for dom0" (due to the dom0_mem=512M).
# These used to be at 0xb... but with the latest U-Boot that makes us hang when
# loading the vmlinuz (use U-Boot's "bdinfo" to see what's in the way).
setenv kernel_addr_r  0xaf600000
setenv xen_addr_r     0xaea00000 # 2M

# sunxi-common.h contains some more useful information:
# CONFIG_SYS_TEXT_BASE  0x4a000000 - location of U-Boot's code
# CONFIG_SYS_SDRAM_BASE 0x40000000 - start of RAM

# Load xen/xen to ${xen_addr_r}.
fatload mmc 0 ${xen_addr_r} /xen
setenv bootargs "console=dtuart dtuart=/soc@01c00000/serial@01c28000 dom0_mem=512M,max:512M"

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
fdt set /chosen/module@0 bootargs "console=hvc0 ro root=/dev/mmcblk0p2 rootwait clk_ignore_unused max_loop=128"

bootz ${xen_addr_r} - ${fdt_addr}
