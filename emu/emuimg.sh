#!/bin/sh
set -eu

if [ $# -ne 5 ]; then
  echo "$(basename "$0") imgfile mbrelf bootelf loaderbin emudir" >&2
  echo "  imgfile   image file" >&2
  echo "  mbrelf    MBR ELF file" >&2
  echo "  bootelf   bootblock ELF file" >&2
  echo "  loaderbin loader binary file" >&2
  echo "  emudir    emulator source directory" >&2
  exit 1
fi

IMGFILE="$1"
IMGSIZE=100M
SECSIZE=512
PARTSTART=2048     # in sectors
PARTSIZE=40960

MBRFILE="$2"
BOOTFILE="$3"
LDRFILE="$4"
LDRTRGPATH=boot

EMUDIR="$5"

ARCH=i386-elf
READELF="$ARCH-readelf"

SFDISK=/sbin/sfdisk
MKFSVFAT=/sbin/mkfs.vfat

# delete image file on error
trap cleanup EXIT
cleanup() {
  errlev=$?
  trap EXIT

  unmount "${LOOPDEV:-}"

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
  "$READELF" -l "$elffile" | \
    awk -f "$EMUDIR/elf.awk" | \
    while read offs offsi fsize; do
      offs=$((offs))
      offsi=$((offsi + offset))
      fsize=$((fsize))
      if [ $fsize -gt 0 ]; then
        dd if="$elffile" of="$imgfile" bs=1 count=$fsize skip=$offs \
           seek=$offsi conv=notrunc status=none
      fi
    done
}

# get file block numbers
# parameters:
# $1: file
getblocks() {
  local ff
  ff=$(sudo filefrag -b"$SECSIZE" -e -s "$1")
  ff=$(echo "$ff" | awk -f "$EMUDIR/filefrag.awk")
  ff=$(seq $ff | \
         while read n; do
           printf "%08x" $n | tac -rs ..
         done)
  echo "$ff" | fold -w 60
}

# create loop device
# parameters
# $1: image file
# $2: sector size in bytes
# $3: partition start in sectors
# $4: partition size in sectors
createloop() {
  local imgfile="$1"
  local offset=$(($2 * $3))
  local size=$(($2 * $4))
  local loopdev

  loopdev=$(udisksctl loop-setup --file "$imgfile" --offset $offset \
                      --size $size --no-user-interaction)
  loopdev=$(echo "$loopdev" | awk '{sub(".$", "", $NF); print $NF}')
  echo "$loopdev"
}

# mount loop image
# parameters:
# $1: loop file
mountloop() {
  local mountpoint
  local loopd="$1"

  for i in 1 2 3 4 5; do
    if udisksctl info --block-device "$loopd" >/dev/null; then
      break
    fi
  done
  mountpoint=$(udisksctl mount --block-device "$loopd" --no-user-interaction)
  mountpoint=$(echo "$mountpoint" | awk '{sub(".$", "", $NF); print $NF}')
  echo "$mountpoint"
}



# unmount image file and delete loop device
# parameters:
# $1: loop device
unmount() {
  local loopdev="$1"

  if [ -n "${loopdev:-}" ]; then
    local bf
    bf=$(udisksctl info --block-device "$loopdev")
    bf=$(echo "$bf" | \
           awk -F '[ :]+' -- \
               '{sub(/ */, "", $0); if ($1 == "MountPoints") {print $2}}')

    if [ -n "$bf" ]; then
      udisksctl unmount --block-device "$loopdev" --no-user-interaction \
                >/dev/null
      udisksctl loop-delete --block-device "$loopdev" --no-user-interaction
    fi
  fi
}

# create image file
rm -f "$IMGFILE"
dd if=/dev/zero of="$IMGFILE" bs="$IMGSIZE" seek=1 count=0 status=none
printf "$PARTSTART, $PARTSIZE, 0xc, *\nwrite\n" | \
  "$SFDISK" "$IMGFILE" >/dev/null

# create loop device
LOOPDEV=$(createloop "$IMGFILE" $SECSIZE $PARTSTART $PARTSIZE)

# create FAT partition
sudo mkfs.vfat "$LOOPDEV" >/dev/null

# MBR
copyelf "$IMGFILE" "$MBRFILE"

# FAT boot sector
copyelf "$IMGFILE" "$BOOTFILE" $((SECSIZE * PARTSTART))

# mount FAT partition
MOUNTPOINT=$(mountloop "$LOOPDEV")

# copy loader bin
trgldrfile="$MOUNTPOINT/$LDRTRGPATH/$(basename "$LDRFILE")"
mkdir -p $(dirname "$trgldrfile")
cp "$LDRFILE" "$trgldrfile"

#create loader blocklist file
blist=$(getblocks "$trgldrfile")
trgblkfile=${trgldrfile%.*}.blk
echo "$blist" | xxd -r -p >"$trgblkfile"

# write block number of block file into bootblock
blk=$(getblocks "$trgblkfile")
blklen=$(echo -n "$blk" | wc -c)
if [ "$blklen" -ne 8 ]; then
  echo "blockfile must fit in 512 bytes" >&2
  exit 1
fi

fblkaddr=$(i386-elf-objdump -t "$BOOTFILE")
fblkaddr=$(echo "$fblkaddr" | awk '{if ($NF == "fblk") {print $1}}')
if [ -z "$fblkaddr" ]; then
  echo "fblk variable not found in $BOOTFILE." >&2
  exit 1
fi
fblkaddr=$((0x$fblkaddr))

# unmount image file and delete loop device
unmount "$LOOPDEV"

echo "$blk" | \
  xxd -r -p | \
  dd of="$IMGFILE" bs=1 seek=$((PARTSTART * SECSIZE + fblkaddr)) \
     conv=notrunc status=none
