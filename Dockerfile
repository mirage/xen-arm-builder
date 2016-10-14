FROM debian:stretch
MAINTAINER Richard Mortier <mort@cantab.net>

RUN apt-get update                              \
    && apt-get -y upgrade                       \
    && apt-get install -y                       \
         bc                                     \
         build-essential                        \
         curl                                   \
         device-tree-compiler                   \
         dosfstools                             \
         gcc-arm-linux-gnueabi                  \
         git                                    \
         man                                    \
         u-boot-tools

VOLUME ["/cwd"]
WORKDIR /cwd

ENTRYPOINT ["bash"]
