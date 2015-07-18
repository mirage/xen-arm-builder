# If you're not on Debian/Ubuntu, you can use this to make a suitable Docker image.
# You'll need to run it with --privileged however.
# To build: docker build -t xen-sdcard-builder .
FROM ubuntu:vivid
RUN apt-get update
RUN apt-get install -y curl gcc-arm-linux-gnueabihf rsync git build-essential kpartx binfmt-support python bc parted dosfstools sudo qemu-utils
RUN sudo mknod /dev/loop0 -m0660 b 7 0
VOLUME /xen-arm-builder
WORKDIR /xen-arm-builder
#docker run --rm -e "http_proxy=http://proxy:3142/" --link apt-cacher:proxy --privileged -it -v `pwd`:/xen-arm-builder -w /xen-arm-builder xen-sdcard-builder
#RUN make clone
#RUN make build
