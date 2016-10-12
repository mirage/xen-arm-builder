# Building Cubieboard Images

Based on <https://gist.github.com/ijc25/612b8b7975e9461c3584b1402df2cb34> from
Ian Campbell.

__IN DEVELOPMENT: USE AT YOUR OWN RISK AND SUBJECT TO CHANGE__

## Create Builder

To create the builder, clone repos, build `u-boot` and `Linux`, and construct
disk image:

```
git clone https://github.com/mor1/arm-image-builder.git
cd arm-image-builder
docker pull mor1/arm-image-builder
docker run -it -v $(pwd):/cwd mor1/arm-image-builder ./clone.sh
docker run -it -v $(pwd):/cwd mor1/arm-image-builder ./u-boot.sh
docker run -it -v $(pwd):/cwd mor1/arm-image-builder ./linux.sh
docker run -it --privileged -v $(pwd):/cwd mor1/arm-image-builder ./image.sh
```
