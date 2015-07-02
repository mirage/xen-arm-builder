.PHONY: all build clean dd img kernel menuconfig tar tgz

BOARD ?= cubieboard2
# BOARD ?= cubietruck
FIRMWARE ?= rtlwifi htc_9271.fw

DISTROVER ?= trusty
include config/$(DISTROVER).mk

all: 
	@echo ------
	@echo "BOARD can be: cubieboard2 (default) or cubietruck"
	@echo "DISTROVER can be: trusty (default) or vivid"
	@echo ""
	@echo "export BOARD=cubieboard2"
	@echo "# select which board you want to build an image for."
	@echo "make clone"
	@echo "# will fetch repositories or pull"
	@echo "make build"
	@echo "# will build xen, u-boot and linux dom0"
	@echo "make img"
	@echo "# builds the image file"
	@echo "make tar"
	@echo "# gives you a sparse tarfile of the image"
	@echo "make dd"
	@echo "# writes the image to a microSD card"
	@echo ------

## Fetch and clone all the external files needed
clone: $(ROOTFS)
	DISTROVER=$(DISTROVER) BUILD_XEN=$(BUILD_XEN) ./clone-repos.sh
	cp config/config-cubie2 linux/.config

ifeq ($(BUILD_XEN),true)
	BUILD_XEN_CMD=./build-xen.sh
else
	BUILD_XEN_CMD=true
endif

linux/.config: config/$(KERNELCONFIG)
	cp config/$(KERNELCONFIG) $@

menuconfig: linux/.config
	$(MAKE) -C linux ARCH=arm menuconfig

build:
	BOARD=$(BOARD) ./build-uboot.sh
	$(BUILD_XEN_CMD)
	./build-linux.sh

## Get the latest Linaro root image
$(ROOTFS):
	curl -OL $(ROOTFSURL)/$(ROOTFS)

## Build the image file
${BOARD}.img: boot/boot-${BOARD}.scr $(ROOTFS)
	sudo env ROOTFS=$(ROOTFS) BOARD=$(BOARD) FIRMWARE="$(FIRMWARE)" DISTROVER=$(DISTROVER) BUILD_XEN=$(BUILD_XEN) ./build.sh || (rm -f $@; exit 1)

img: $(BOARD).img

## Make a sparse (smaller, but source must be read twice) archive of the image file
%.tar: %.img
	rm -f $@
	tar -Scf $@ $<

tar: $(BOARD).tar

## Make a sparse and compressed archive of the image file
%.tar.gz: %.img
	rm -f $@
	tar -Szcf $@ $<

tgz: $(BOARD).tar.gz

dd: $(BOARD).img
	sudo dd if=$(BOARD).img of=/dev/mmcblk0 bs=4096

## Generate the u-boot boot commands script
%.scr: %.cmd
	./u-boot-sunxi/build-${BOARD}/tools/mkimage -C none -A arm -T script -d "$<" "$@"

clean:
	rm -f cubie*.img boot/boot.*.scr
	cd u-boot-sunxi && $(MAKE) mrproper
