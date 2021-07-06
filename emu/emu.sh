#!/bin/sh
set -eu

if [ $# -ne 1 ]; then
  echo "$(basename "$0") imgfile" >&2
  exit 1
fi

IMGFILE="$1"

PAR="-machine pc"
PAR="$PAR -cpu 486"
PAR="$PAR -m 2"
PAR="$PAR -drive file=$IMGFILE,if=virtio,bus=0,unit=0,media=disk,format=raw"
PAR="$PAR -boot order=c"
PAR="$PAR -net none"
PAR="$PAR -serial none"
PAR="$PAR -parallel none"
if [ -z "${DISPLAY:-}" ]; then
  PAR="$PAR -curses"
  if [ "${TERM:-dumb}" = dumb ]; then
    PAR="$PAR -monitor stdio"
  fi
fi

qemu-system-i386 $PAR
