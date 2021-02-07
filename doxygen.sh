#!/bin/sh
set -eu

BUILDDIR=/tmp/lgos
if [ ! -e "$BUILDDIR" ]; then
  mkdir "$BUILDDIR"
fi
doxygen doc/lgos.conf
