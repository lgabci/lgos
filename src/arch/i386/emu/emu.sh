#!/bin/sh
set -eu

if [ $# -ne 1 ]; then
  echo "$(basename $0) usage" >&2
  echo "  $1: image file name" >&2
  exit 2
fi

imgfile=$1

qemu-system-i386 -cpu 486 -smp cpus=1 -boot order=c -m 1 \
                 -drive file=$imgfile,if=ide,index=0,media=disk,format=raw \
                 -no-acpi -no-hpet -nic none -serial none -parallel none \
                 -rtc base=localtime
