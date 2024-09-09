#!/bin/sh
set -eu

basename=$(basename $0)

error() {
  echo "$basename: $1" >&2
  exit 1
}

if [ $# -ne 3 ]; then
  echo "$basename: bad argument list" >&2
  echo "\t$@" >&2
  exit 1
fi

imgfile="$1"
imgsize="$2"
mbrbin="$3"

sfdisk=$(whereis -b sfdisk | awk '{print $2}')
[ -n "$sfdisk" ] || error "no sfdisk found"

# create image file
qemu-img create -q -f raw "$imgfile" "$imgsize"
dd if="$mbrbin" of="$imgfile" bs=512 conv=notrunc status=none

# create partition table
echo ',20M,,*' |
  "$sfdisk" --no-reread --no-tell-kernel --label dos -q "$imgfile"
