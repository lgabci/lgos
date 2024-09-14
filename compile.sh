#!/bin/sh
set -eu

srcdir="$HOME/projects/lgos"
blddir="/tmp/lgos"
arch=${ARCH:-$(arch)}

case "${1:-}" in
  clean)
    rm -rf "$blddir"
    ;;
  *)
    if ! [ -e "$blddir/build.ninja" ]; then
      meson setup --cross-file "$srcdir/src/arch/$arch/meson-cross.txt" \
            "$srcdir" "$blddir"
    fi
    case "${1:-}" in
      "")
      meson compile -C "$blddir"
      ;;
    *)
      meson compile -C "$blddir" "$1"
      ;;
    esac
  ;;
esac
