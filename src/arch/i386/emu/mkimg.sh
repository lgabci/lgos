#!/bin/sh

set -eu

# parameters:
# 1. image file
# 2. MBR ELF

imgfile="$1"
mbrelf="$2"
imgsize=104857600    # 100 MB
partstart=2048       # partition start in sectors
partsize=20480       # partition size in sectors

# copy ELF file into a file
# args:
#  1. file to write ELF into
#  2. ELF file
#  3. byte offset in file
copyelf () {
  file="$1"
  elf="$2"

  x86_64-elf-readelf -Sw "$elf" | \
    awk -F '[][ ]+' -- '{
      if ($2 ~ /^[0-9]+$/ && $4 == "PROGBITS") {
        print $5 " " $6 " " $7
      }
    }' | \
      while read offs foffs len; do
        echo . $((0x$offs)) $((0x$foffs)) $((0x$len)) >&2  ###
        dd if="$elf" of="$file" bs=1 skip=$((0x$foffs)) seek=$((0x$offs))\
           count=$((0x$len)) conv=notrunc status=none
      done
}

# find executable (if not in PATH)
# args:
#  1: executable file name
findprog () {
  _prog="$1"

  _fullpath=$(whereis -b $_prog | awk '{print $2}')
  if [ -z "$_fullpath" ]; then
    die "Executable \"$_prog\" not found."
  fi
  echo "$_fullpath"

  unset _prog
  unset _fullpath
}

truncate -s "$imgsize" "$imgfile"

parted=$(findprog parted)
"$parted" -s "$imgfile" \
          mklabel msdos \
          mkpart primary fat16 "$partstart"s "$((partstart + partsize))"s \
          set 1 boot on

copyelf "$imgfile" "$mbrelf" 0
