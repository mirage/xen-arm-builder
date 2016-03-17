.PHONY: all build clean dd img kernel menuconfig tar tgz

BOARD ?= cubieboard2
# BOARD ?= cubietruck
FIRMWARE ?= rtlwifi htc_9271.fw

DISTROVER ?= trusty
include config/$(DISTROVER).mk

# Add an optional apt-cacher-ng proxy running in another docker container
# (using the IP address rather than the hostname)
# Run with: docker run --link apt-cacher:proxy ...
ifdef PROXY_PORT_3142_TCP_ADDR
	http_proxy = http://$(PROXY_PORT_3142_TCP_ADDR):$(PROXY_PORT_3142_TCP_PORT)/
endif

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

ifeq ($(BUILD_XEN),true)
	BUILD_XEN_CMD=./build-xen.sh
else
	BUILD_XEN_CMD=true
endif

linux/.config: config/$(KERNELCONFIG)
	cp config/$(KERNELCONFIG) $@

menuconfig: linux/.config
	test -f /usr/include/curses.h || sudo apt-get -y install libncurses5-dev
	$(MAKE) -C linux ARCH=arm menuconfig

build: linux/.config
	BOARD=$(BOARD) ./build-uboot.sh
	$(BUILD_XEN_CMD)
	DISTROVER=$(DISTROVER) ./build-linux.sh

## Get the latest Linaro root image
$(ROOTFS):
	curl -OL $(ROOTFSURL)/$(ROOTFS)

## Build the image file
${BOARD}.img: boot/boot-${BOARD}.scr $(ROOTFS)
	sudo env ROOTFS=$(ROOTFS) BOARD=$(BOARD) FIRMWARE="$(FIRMWARE)" DISTROVER=$(DISTROVER) BUILD_XEN=$(BUILD_XEN) INSTALL_XAPI=$(INSTALL_XAPI) http_proxy="$(http_proxy)" ./build.sh || (rm -f $@; exit 1)

## Make a sparse (smaller, but source must be read twice) archive of the image file
%.tar: %.img
	rm -f $@
	tar -Scf $@ $<

## Make a sparse and compressed archive of the image file
%.tar.gz: %.img
	rm -f $@
	tar -Szcf $@ $<

## Convenience, avoiding the need to repeat yourself about which board
img: $(BOARD).img
tar: $(BOARD).tar
tgz: $(BOARD).tar.gz

## Generate the u-boot boot commands script
%.scr: %.cmd
	./u-boot/build-${BOARD}/tools/mkimage -C none -A arm -T script -d "$<" "$@"

clean:
	rm -f cubie*.img boot/boot.*.scr
	cd u-boot && $(MAKE) mrproper
