.PHONY: all clean

ROOTFS ?= linaro-trusty-developer-20140522-661.tar.gz
ROOTFSURL ?= http://releases.linaro.org/14.05/ubuntu/trusty-images/developer/
BOARD ?= cubieboard2
# BOARD ?= cubietruck
FIRMWARE ?= rtlwifi htc_9271.fw

# files required to build the final image
TARGET_FILES := \
    boot/boot-${BOARD}.scr \
    u-boot/build-${BOARD}/u-boot-sunxi-with-spl.bin \
    linux/arch/arm/boot/zImage \
    linux/arch/arm/boot/dts/sun7i-a20-cubieboard2.dtb \
    linux/arch/arm/boot/dts/sun7i-a20-cubietruck.dtb \
    xen/xen/xen

all: 
	@echo ------
	@echo "BOARD can be: cubieboard2 (default) or cubietruck"
	@echo ""
	@echo "export BOARD=cubieboard2"
	@echo "# select which board you want to build an image for."
	@echo "make clone"
	@echo "# will fetch repositories or pull"
	@echo "make build"
	@echo "# will build xen, u-boot and linux dom0"
	@echo "make $${BOARD}.tar"
	@echo "# gives you a sparse tarfile of the image"
	@echo ------

## Fetch and clone all the external files needed
clone: $(ROOTFS)
	./clone-repos.sh

build:
	BOARD=$(BOARD) ./build-uboot.sh
	./build-xen.sh
	cp config/config-cubie2 linux/.config
	./build-linux.sh

## Get the latest Linaro root image
$(ROOTFS):
	curl -OLf $(ROOTFSURL)/$(ROOTFS)

## Build the image file
${BOARD}.img: $(ROOTFS) $(TARGET_FILES)
	sudo env ROOTFS=$(ROOTFS) BOARD=$(BOARD) FIRMWARE="$(FIRMWARE)" ./build.sh || (rm -f $@; exit 1)

## Make a sparse (smaller, but source must be read twice) archive of the image file
%.tar: %.img
	rm -f $@
	tar -Scf $@ $<

## Make a sparse and compressed archive of the image file
%.tar.gz: %.img
	rm -f $@
	tar -Szcf $@ $<

## Generate the u-boot boot commands script
%.scr: %.cmd
	./u-boot/build-${BOARD}/tools/mkimage -C none -A arm -T script -d "$<" "$@"

clean:
	rm -f cubie*.img boot/boot.*.scr
	if [ -d u-boot ]; then cd u-boot && $(MAKE) mrproper; else true; fi
	if [ -d linux ]; then cd linux && $(MAKE) mrproper; else true; fi
	if [ -d xen ]; then cd xen && $(MAKE) mrproper; else true; fi
