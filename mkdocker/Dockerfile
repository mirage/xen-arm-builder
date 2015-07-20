# If you're not on Debian/Ubuntu, you can use this to make a suitable Docker image.
# You'll need to run it with --privileged however.
# To build: docker build -t xen-sdcard-builder .
FROM ubuntu:trusty
RUN sudo apt-get update
RUN sudo apt-get install -y curl gcc-arm-linux-gnueabihf rsync git build-essential qemu kpartx binfmt-support qemu-user-static python bc parted dosfstools
RUN sudo mknod /dev/loop0 -m0660 b 7 0
#ADD . /build
#WORKDIR /build
#RUN make clone
#RUN make build
