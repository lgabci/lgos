#!/bin/sh
set -eu

./build.sh

BUILDDIR=/tmp/lgos
IMGFILE="$BUILDDIR/emu/lgos.img"
IMGSIZE=100M

MBRFILE="$BUILDDIR/arch/i386/bootblock/main_mbr.bin"

# create image file
imgdir="$(dirname "$IMGFILE")"
if [ ! -e "$imgdir" ]; then
  mkdir -p "$imgdir"
fi
dd if="$MBRFILE" of="$IMGFILE" status=none
dd if=/dev/zero of="$IMGFILE" bs="$IMGSIZE" seek=1 count=0 status=none

qemu-system-i386 -machine pc -cpu 486 -boot order=c -m 2 \
  -drive file="$IMGFILE",if=virtio,bus=0,unit=0,media=disk,format=raw
