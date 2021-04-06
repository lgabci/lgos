#!/bin/sh
set -eu

RUNDIR=$(dirname "$0")
BUILDDIR=/tmp/lgos
ELFFILE="$BUILDDIR/arch/i386/bootblock/main_mbr.elf"

"$RUNDIR/build.sh"

func="${1:-}"
i386-elf-objdump -d -Maddr16,data16 "$ELFFILE" |
  if [ -n "$func" ]; then
    sed -e "/^[[:xdigit:]]\+ <$func>:$/,/^$/!d"
  else
    cat
  fi
