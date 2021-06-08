#!/bin/sh
set -eu

RUNDIR=$(dirname "$0")
BUILDDIR=/tmp/lgos
IMGFILE="$BUILDDIR/emu/lgos.img"
IMGSIZE=100M

MBRFILE="$BUILDDIR/arch/i386/bootblock/main_mbr.elf"
FATFILE="$BUILDDIR/arch/i386/bootblock/main_fat.elf"
LDRFILE="$BUILDDIR/arch/i386/loader/main_loader.bin"
LDRTRGPATH=boot

ARCH=i386-elf
READELF="$ARCH-readelf"

SFDISK=/usr/sbin/sfdisk
MKFSVFAT=/usr/sbin/mkfs.vfat

SECSIZE=512
PARTSTART=2048
PARTSIZE=40960

"$RUNDIR/build.sh"

# delete image file on error
trap cleanup EXIT
cleanup() {
  errlev=$?
  trap EXIT

  if [ -n "${LOOPDEV:-}" ]; then
    if [ -n "${MOUNTPOINT:-}" ]; then
      udisksctl unmount --block-device "$LOOPDEV" --no-user-interaction \
                >/dev/null
    fi
    udisksctl loop-delete --block-device "$LOOPDEV" --no-user-interaction
  fi

  if [ $errlev -ne 0 ]; then
    rm -rf "$IMGFILE"
  fi
}

# copy ELF file into image
# parameters:
# $1: image file
# $2: ELF file
# $3: offset in image file
copyelf() {
  local imgfile="$1"
  local elffile="$2"
  local offset=${3:-0}
  echo "copyelf $elffile" ##
  "$READELF" -l "$elffile" | \
    awk -f "$RUNDIR/emu/elf.awk" | \
    while read offs offsi fsize; do
      offs=$((offs))
      offsi=$((offsi + offset))
      fsize=$((fsize))
      if [ $fsize -gt 0 ]; then
        if ! cmp -s -n $fsize "$elffile" "$imgfile" $offs $offsi; then
          echo $offs $offsi $fsize ##
          dd if="$elffile" of="$imgfile" bs=1 count=$fsize skip=$offs \
             seek=$offsi conv=notrunc status=none
        fi
      fi
    done
}

# get file block numbers
# parameters:
# $1: file
getblocks() {
  local ff
  ff=$(sudo filefrag -b"$SECSIZE" -e -s "$1")
  ff=$(echo "$ff" | awk -f emu/filefrag.awk)
  ff=$(seq $ff | \
         while read n; do
           printf "%08x" $n
         done)
  echo "$ff" | fold -w 60
}

# create image file
if [ ! -e "$IMGFILE" ]; then
  imgdir=$(dirname "$IMGFILE")
  if [ ! -e "$imgdir" ]; then
    mkdir -p "$imgdir"
  fi

  dd if=/dev/zero of="$IMGFILE" bs="$IMGSIZE" seek=1 count=0 status=none
  printf "$PARTSTART, $PARTSIZE, 0xc, *\nwrite\n" | \
    "$SFDISK" "$IMGFILE" >/dev/null
fi

LOOPDEV=$(udisksctl loop-setup --file "$IMGFILE" --offset \
                    $((PARTSTART * SECSIZE)) --size \
                    $((PARTSIZE * SECSIZE)) --no-user-interaction)
LOOPDEV=$(echo "$LOOPDEV" | awk '{sub(".$", "", $NF); print $NF}')

# create FAT partition
fstype=$(sudo file -bs "$LOOPDEV")
if ! echo "$fstype" | grep -q 'OEM-ID "mkfs.fat"'; then
  sudo mkfs.vfat "$LOOPDEV" >/dev/null
fi

# MBR
copyelf "$IMGFILE" "$MBRFILE"

# FAT boot sector
copyelf "$IMGFILE" "$FATFILE" $((SECSIZE * PARTSTART))

# mount FAT partition
for a in 1 2 3 4 5; do
  fstype=$(udisksctl info --block-device "$LOOPDEV")
  fstype=$(echo "$fstype" | awk '/IdType:/ {print $2}')
  if [ "$fstype" = vfat ]; then
    break
  fi
done
if [ -z "$fstype" ]; then
  echo "Bad FS on $LOOPDEV." >&2
  exit 1
fi
MOUNTPOINT=$(udisksctl mount --block-device "$LOOPDEV" --no-user-interaction)
MOUNTPOINT=$(echo "$MOUNTPOINT" | awk '{sub(".$", "", $NF); print $NF}')

# copy loader bin
trgldrfile="$MOUNTPOINT/$LDRTRGPATH/$(basename "$LDRFILE")"
if [ ! "$LDRFILE" -ot "$trgldrfile" ]; then
  mkdir -p $(dirname "$trgldrfile")
  cp "$LDRFILE" "$trgldrfile"
  touch -d "+2seconds" "$trgldrfile"
fi

#create loader blocklist file
blist=$(getblocks "$trgldrfile")
trgblkfile=${trgldrfile%.*}.blk
if ! echo "$blist" | xxd -r -p -e | cmp -s "$trgblkfile" -; then
  echo "$blist" | xxd -r -p -e >"$trgblkfile"
fi

# write block number of block file into bootblock
blk=$(getblocks "$trgblkfile")
blk=12345678   ##
blklen=$(echo -n "$blk" | wc -c)
if [ "$blklen" -ne 8 ]; then
  echo "blockfile must fit in 512 bytes" >&2
  exit 1
fi

fblkaddr=$(i386-elf-objdump -t "$FATFILE")
fblkaddr=$(echo "$fblkaddr" | awk '{if ($NF == "fblk") {print $1}}')
if [ -z "$fblkaddr" ]; then
  echo "fblk variable not found in $FATFILE." >&2
  exit 1
fi
fblkaddr=$((0x$fblkaddr + SECSIZE * PARTSTART))
fblk=$(dd if="$IMGFILE" bs=1 count=4 skip="$fblkaddr" status=none | \
         xxd -p -e)

echo "$blk $fblk $fblkaddr" ##
if [ "$blk" != "$fblk" ]; then
  echo "blk" ##
  echo "$blk" | \
    xxd -r -p -e | \
    dd of="$IMGFILE" bs=1 seek="$fblkaddr" conv=notrunc status=none
fi

# start Qemu
PAR="-machine pc -cpu 486"
PAR="$PAR -m 2"
PAR="$PAR -drive file=$IMGFILE,if=virtio,bus=0,unit=0,media=disk,format=raw"
PAR="$PAR -boot order=c"
PAR="$PAR -net none"
PAR="$PAR -serial none -parallel none"
if [ -z "${DISPLAY:-}" ]; then
  PAR="$PAR -curses"
  if [ "${TERM:-dumb}" = dumb ]; then
    PAR="$PAR -monitor stdio"
  fi
fi

qemu-system-i386 $PAR
