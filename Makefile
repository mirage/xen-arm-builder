.PHONY: all clean

all: cubie.img
	@ :

cubie.img:
	sudo ./build.sh

clean:
	rm -f cubie.img
