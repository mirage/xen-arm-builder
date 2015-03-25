#!/bin/sh -ex

KNOWN_BOARDS="cubieboard2 cubietruck"
DESTDIR=$1
if [ "${DESTDIR}" = "" ]; then
  echo Usage: $0 output-dir
  exit 1
fi

mkdir -p ${DESTDIR}
rev=`git rev-parse --short HEAD`
for i in $KNOWN_BOARDS; do
  export BOARD=$i
  make clean
  make clone
  make build
  make $i.tar
  ofile="${DESTDIR}/$i-${rev}.tar"
  mv $i.tar $ofile
  ln -nfs $i-${rev}.tar ${DESTDIR}/$i.tar 
done
