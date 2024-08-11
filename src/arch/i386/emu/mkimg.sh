#!/bin/sh
set -eu

if [ $# -ne 3 ]; then
  echo "$(basename $0): bad argument list" >&2
  echo "\t$@" >&2
  exit 1
fi

imgfile="$1"
imgsize="$2"
mbrbin="$3"

qemu-img create -q -f raw "$imgfile" "$imgsize"
dd if="$mbrbin" of="$imgfile" bs=512 conv=notrunc status=none
