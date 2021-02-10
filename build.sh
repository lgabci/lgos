#!/bin/sh
set -eu

SRCDIR=src
BUILDDIR=/tmp/lgos

NINJAFILE=build.ninja

if [ ! -e "$BUILDDIR/$NINJAFILE" ]; then
  mkdir -p "$BUILDDIR"
  meson setup --cross-file src/arch/i386/meson.ini "$SRCDIR" "$BUILDDIR"
fi
ninja -C "$BUILDDIR"
