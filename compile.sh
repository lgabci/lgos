#!/bin/sh
set -eu

srcdir="$HOME/projects/lgos"
blddir="/tmp/lgos"
arch=${ARCH:-i386}

case "${1:-}" in
  clean)
    rm -rf "$blddir"
    ;;
  *)
    if ! [ -e "$blddir/build.ninja" ]; then
      meson setup --cross-file "$srcdir/src/arch/$arch/meson-cross.txt" \
            "$srcdir" "$blddir"
    fi
    meson compile -C "$blddir" $@
esac
