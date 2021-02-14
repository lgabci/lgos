#!/bin/sh
set -eu

./build.sh

ELFFILE=/tmp/lgos/arch/i386/bootblock/main_mbr.elf
if [ -e "$ELFFILE" ]; then
  i386-elf-objdump -d -M addr16,data16 "$ELFFILE"
fi
