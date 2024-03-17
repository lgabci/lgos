#!/bin/sh
set -eu

if [ $# -ne 2 ]; then
  echo "$(basename $0) usage" >&2
  echo "  $1: image file name" >&2
  echo "  $2: mbr binary file name" >&2
  exit 2
fi

imgfile=$1
mbr=$2

truncate $imgfile -s 10M
dd if=$mbr of=$imgfile bs=512 conv=notrunc status=none
