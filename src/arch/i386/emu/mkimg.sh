#!/bin/sh
# LGOS i386 image maker shell script

set -eu

# prints error message and stops script with error code 1
# args:
#  1. error message
die () {
  msg="$1"

  echo "$msg" >&2
  exit 1
}

basename=$(basename "$0")
if [ "$#" -ne 4 ]; then
  die "$basename: make emulator disk image
args:
  imgfile:   file to write ELF into
  part type: FAT/Ext2
  mbrelf:    MBR ELF file, only for HDD image
  bootelf:   boot ELF file"
fi

imgfile="$1"
parttype="$2"
mbrelf="$3"
bootelf="$4"

case "$parttype" in
  "FAT"|"fat")
    ptype="0c"
    ;;
  "Ext2"|"ext2")
    ptype="83"
    ;;
  *)
    die "Unknown partition type: $parttype"
    ;;
esac

imgsize=104857600    # image size in bytes, 100 MB
partstart=2048       # partition start in sectors
partsize=20480       # partition size in sectors

secsize=512

# copy ELF file into a file
# args:
#  1. image file to write ELF into
#  2. ELF file
#  3. byte offset in file
copyelf () {
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
      dd if="$elffile" of="$imgfile" bs=1 skip=$((0x$foffs)) \
         seek=$((0x$offs + offset)) count=$((0x$len)) conv=notrunc status=none
    done
}

# find an executable file
# args:
#  1. program name
findprog() {
  progname="$1"

  prog=$(whereis -b "$progname" | awk -F '[: ]+' -- '{print $2}')
  if [ -z "$prog" ]; then
    die "program not found: $progname"
  fi
  echo "$prog"
}

# main part of script ---------------------------------------------------------
truncate -s "$imgsize" "$imgfile"

sfdisk=$(findprog sfdisk)
echo "$partstart,$partsize,$ptype,*" |
  "$sfdisk" -q --sector-size 512 -X dos "$imgfile"

case "$parttype" in
  "Ext2"|"ext2")
    mkfs_ext2=$(findprog mkfs.ext2)
    "$mkfs_ext2" -E offset=$((partstart * secsize)) -q "$imgfile" \
                 $((partsize * secsize / 1024))k
    ;;
  "FAT"|"fat")
    mkfs_fat=$(findprog mkfs.vfat)
    "$mkfs_fat" -v --offset "$partstart" "$imgfile" \
                $((partsize * secsize / 1024))
    ;;
esac

copyelf "$imgfile" "$mbrelf" 0
copyelf "$imgfile" "$bootelf" $((partstart * secsize))
