#!/bin/sh

set -eu

# parameters:
# 1. image file
# 2. MBR binary

imgsize=104857600    # 100 MB

imgfile="$1"
mbrbin="$2"

truncate -s "$imgsize" "$imgfile"
dd if="$mbrbin" of="$imgfile" bs=512 conv=notrunc iflag=fullblock
