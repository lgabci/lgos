#!/bin/sh

set -eu

# parameters:
# 1. image file
# 2. MBR ELF

imgfile="$1"
mbrelf="$2"
imgsize=104857600    # 100 MB

# copy ELF file into a file
# args:
#  1. file to write ELF into
#  2. ELF file
#  3. byte offset in file
copyelf () {
  file="$1"
  elf="$2"

  x86_64-elf-readelf -Sw "$elf" | \
    awk -F '[ \[\]]+' -- '{
      if ($2 ~ /^[0-9]+$/ && $4 == "PROGBITS") {
        print $5 " " $6 " " $7
      }
    }' | \
      while read offs foffs len; do
        echo . $((0x$offs)) $((0x$foffs)) $((0x$len))
        dd if="$elf" of="$file" bs=1 skip=$((0x$foffs)) seek=$((0x$offs))\
           count=$((0x$len)) status=none
      done
}

truncate -s "$imgsize" "$imgfile"

copyelf "$imgfile" "$mbrelf" 0
