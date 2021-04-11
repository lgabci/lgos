#!/bin/sh
set -eu

RUNDIR=$(dirname "$0")
BUILDDIR=/tmp/lgos
IMGFILE="$BUILDDIR/emu/lgos.img"
IMGSIZE=100M

MBRFILE="$BUILDDIR/arch/i386/bootblock/main_mbr.elf"
FATFILE="$BUILDDIR/arch/i386/bootblock/main_fat.elf"

ARCH=i386-elf
READELF="$ARCH-readelf"

"$RUNDIR/build.sh"

# check date of files
[ ! -e "$IMGFILE" -o "$MBRFILE" -nt "$IMGFILE" ] && mbrcp="Y" || mbrcp="N"
[ ! -e "$IMGFILE" -o "$FATFILE" -nt "$IMGFILE" ] && fatcp="Y" || fatcp="N"

# create image file
imgdir="$(dirname "$IMGFILE")"
if [ ! -e "$imgdir" ]; then
  mkdir -p "$imgdir"
fi
if [ ! -e "$IMGFILE" ]; then
  dd if="$RUNDIR/emu/mbr.bin" of="$IMGFILE" status=none
  dd if=/dev/zero of="$IMGFILE" bs="$IMGSIZE" seek=1 count=0 status=none
fi

if [ "$mbrcp" = "Y" ]; then
  "$READELF" -l "$MBRFILE" | \
    awk -v imgfile="$IMGFILE" -v mbrfile="$MBRFILE" -f "$RUNDIR/emu/mbr.awk" | \
    sh
fi

if [ "$fatcp" = "Y" ]; then
  "$READELF" -l "$FATFILE" | \
    awk -v imgfile="$IMGFILE" -v mbrfile="$FATFILE" -v offset='2048*512' -f "$RUNDIR/emu/mbr.awk" | \
    sh
fi

# start Qemu
PAR="-machine pc -cpu 486"
PAR="$PAR -m 2"
PAR="$PAR -drive file=$IMGFILE,if=virtio,bus=0,unit=0,media=disk,format=raw"
PAR="$PAR -boot order=c"
PAR="$PAR -net none"
PAR="$PAR -serial none -parallel none"
if [ -z "${DISPLAY:-}" ]; then
  PAR="$PAR -curses"
  if [ "${TERM:-dumb}" = dumb ]; then
    PAR="$PAR -monitor stdio"
  fi
fi

qemu-system-i386 $PAR
