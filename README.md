# Building Cubieboard Images

Based on <https://gist.github.com/ijc25/612b8b7975e9461c3584b1402df2cb34> from
Ian Campbell.

__IN DEVELOPMENT: USE AT YOUR OWN RISK AND SUBJECT TO CHANGE__

## Create Builder

To create the builder, clone repos, build `u-boot` and `Linux`, and construct
disk image:

```
cd builder
docker build -t builder .
docker run -it -v $(pwd):/cwd builder ./clone.sh
docker run -it -v $(pwd):/cwd builder ./u-boot.sh
docker run -it -v $(pwd):/cwd builder ./linux.sh
docker run -it --privileged -v $(pwd):/cwd builder ./image.sh
```
