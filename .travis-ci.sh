#!/bin/sh -ex

sudo apt-get update
make clone
make build
make cubie.img
