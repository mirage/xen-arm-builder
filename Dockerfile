FROM ubuntu:trusty
RUN sudo apt-get update
RUN sudo apt-get install -y build-essential curl
ADD . /build
WORKDIR /build
RUN make clone
RUN make build
