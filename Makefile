.PHONY: shell prepare build image sdcard clean find-mnt

MNT ?= NOTHING-IS-MOUNTED
CWD  = $$(pwd)
DOCKER = docker run -it -v $(CWD):/cwd \
  -e TARGET -e DTB -e ALPINEV -e ALPINETGZ -e SDSIZE -e UBOOTBIN -e ZIMAGE

shell:
	$(DOCKER) --privileged mor1/arm-image-builder

prepare:
	$(DOCKER) mor1/arm-image-builder ./clone.sh

build:
	$(DOCKER) mor1/arm-image-builder ./u-boot.sh
	$(DOCKER) mor1/arm-image-builder ./linux.sh

image: sdcard.img
sdcard.img: $(wildcard *.sh)
	$(DOCKER) mor1/arm-image-builder ./image.sh

find-mnt:
	@echo -n MNT=/dev/r
	@diskutil list \
	  | grep "NO NAME" | tr -s " " \
	  | cut -f 8 -d " " | cut -f -2 -d "s"

sdcard:
	sudo diskutil unmountDisk $(MNT)
	sudo dd if=sdcard.img of=$(MNT) bs=1m
	sudo diskutil eject $(MNT)

clean:
	$(RM) sdcard.img
