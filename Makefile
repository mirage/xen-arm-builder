.PHONY: shell prepare build image sdcard clean find-mnt all

CWD  = $$(pwd)
DOCKER = docker run -it -v $(CWD):/cwd             \
  -e TARGET -e SDSIZE -e V -e J -e TARGETlc -e DTB \
  -e ALPINEV -e ALPINETGZ -e UBOOTBIN -e ZIMAGE
UNAMES := $(shell uname -s)

shell:
	$(DOCKER) --privileged mor1/arm-image-builder

all: prepare build image

prepare:
	$(DOCKER) mor1/arm-image-builder ./clone.sh

build:
	$(DOCKER) mor1/arm-image-builder ./u-boot.sh
	$(DOCKER) mor1/arm-image-builder ./linux.sh

image: sdcard.img
sdcard.img: $(wildcard *.sh) $(wildcard $$ZIMAGE $$DTB src/u-boot/boot.scr)
	# sparse file appears to need to already exist, so touch to create
	$(RM) sdcard.img && touch sdcard.img
	$(DOCKER) --privileged mor1/arm-image-builder ./image.sh

ifeq ($(UNAMES),Darwin)

DEFAULT_MNT := $$(make find-mnt)
MNT ?= $(DEFAULT_MNT)

find-mnt:
	@echo -n /dev/r
	@diskutil list \
	  | grep "NO NAME" | tr -s " " \
	  | cut -f 8 -d " " | cut -f -2 -d "s"

sdcard:
	sudo diskutil unmountDisk $(MNT) || true
	sudo dd if=sdcard.img of=$(MNT) bs=1m
	sudo diskutil eject $(MNT)

else # not OSX

sdcard:
	@echo "Cannot write sdcard on $(UNAMES)" && false

endif

clean:
	$(RM) sdcard.img
