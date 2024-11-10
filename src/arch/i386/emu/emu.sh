#!/bin/sh
set -eu

if [ $# -ne 2 ]; then
  echo "$(basename $0): bad argument list" >&2
  echo "\t$@" >&2
  exit 1
fi

disktype="$1"
imgfile="$2"

qemuargs="-machine isapc -cpu 486 -accel kvm -m 2"
qemuargs="$qemuargs -no-acpi -no-hpet -nic none -serial none"
qemuargs="$qemuargs -parallel none -rtc base=localtime"

case "$disktype" in
  hd)
    qemuargs="$qemuargs -drive file=$imgfile,if=ide,index=0,media=disk"
    qemuargs="$qemuargs,format=raw -boot order=c"
    ;;
  fd)
    qemuargs="$qemuargs -drive file=$imgfile,if=floppy,index=0,media=disk"
    qemuargs="$qemuargs,format=raw -boot order=a"
    ;;
  *)
    echo "$(basename $0): unknown disk type: $disktype" >&2
    exit 1
    ;;
esac

qemu-system-i386 $qemuargs
