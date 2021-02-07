#!/bin/sh
set -eu

SRCDIR=src
BUILDDIR=/tmp/lgos
rm -rf "$BUILDDIR"
meson setup --cross-file src/arch/i386/meson.ini "$SRCDIR" "$BUILDDIR"
