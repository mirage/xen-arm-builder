.PHONY: all clean

ROOTFS ?= linaro-trusty-developer-20140428-654.tar.gz
ROOTFSURL ?= http://snapshots.linaro.org/ubuntu/images/developer/latest/

all: cubie.img
	@ :

## Fetch and clone all the external files needed
clone: $(ROOTFS)
	./clone-repos.sh

## Get the latest Linaro root image
$(ROOTFS):
	curl -OL $(ROOTFSURL)/$(ROOTFS)

## Build the image file
cubie.img: boot/boot.scr
	sudo ./build.sh

## Make a sparse (smaller) archive of the image file
cubie.tar: cubie.img
	rm -f cubie.tar
	tar -Scf $@ $<

## Generate the u-boot boot commands script
%.scr: %.cmd
	./u-boot-sunxi/tools/mkimage -C none -A arm -T script -d "$<" "$@"
	
clean:
	rm -f cubie.img
