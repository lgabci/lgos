#!/bin/sh
set -eu

if [ $# -ne 1 ]; then
  echo "$(basename $0): bad argument list" >&2
  echo "\t$@" >&2
  exit 1
fi

imgfile="$1"

qemu-system-i386 -machine isapc -cpu 486 -accel kvm -boot order=c -m 2 \
                 -drive file="$imgfile",if=ide,index=0,media=disk,format=raw \
                 -no-acpi -no-hpet -nic none -serial none -parallel none \
                 -rtc base=localtime
