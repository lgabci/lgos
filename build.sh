#!/bin/sh
set -eu

dirname=$(dirname "$0")
cd "$dirname"

nproc=$(nproc)
if [ -z "$nproc" ]; then
  nproc=1
fi

ARCH=i386 BUILDDIR=/tmp/lgos make -j "$nproc" $@
