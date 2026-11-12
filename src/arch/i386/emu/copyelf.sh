#!/bin/sh
set -eu

basename=$(basename "$0")
if [ "$#" -ne 3 ]; then
  echo "$basename: copy ELF file into a file" >&2
  echo "args:" >&2
  echo "  imgfile: file to write ELF into" >&2
  echo "  elffile: ELF file" >&2
  echo "  offset:  byte offset in file" >&2
  exit 1
fi

imgfile="$1"
elffile="$2"
offset="$3"

fieldsep='[][ ]+'
prog='{
        if ($2 ~ /^[0-9]+$/ && $4 == "PROGBITS") {
          print $5 " " $6 " " $7
        }
     }'

x86_64-elf-readelf -SW "$elffile" | \
  awk -F "$fieldsep" -- "$prog" | \
  while read offs foffs len; do
    echo . $((0x$offs)) $((0x$foffs)) $((0x$len)) >&2  ###
    dd if="$elffile" of="$imgfile" bs=1 skip=$((0x$foffs)) \
       seek=$((0x$offs)) count=$((0x$len)) conv=notrunc status=none
  done
