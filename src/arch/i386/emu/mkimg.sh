#!/bin/sh
set -eu

basename=$(basename $0)

# print error message and exit with 1 exit status
error() {
  echo "$basename: $1" >&2
  exit 1
}

# find executable file, throws error if not found
findex() {
  local fname="${1:-}"
  [ -n "$fname" ] || error "findex: empty filename."
  local ret=$(whereis -b "$fname" | awk '{print $2}')
  [ -n "$ret" ] || error "findex: $fname not found."
  echo "$ret"
}


if [ $# -ne 9 ]; then
  echo "$basename: bad argument list" >&2
  echo "\t$@" >&2
  exit 1
fi

imgfile="$1"
fstype="$2"
imgsize="$3"
mbrelf="$4"
mbrbin="$5"
bootelf="$6"
bootbin="$7"
loaderelf="$8"
loaderbin="$9"

startsec="2048"
psize="20M"

# set symbol address
# parameters: 1. img file
#             2. elf file offset in img file
#             3. elf file
#             4. symbol name
#             5. symbol lenght
#             6. value
set_sym() {
  local filenam="$1"
  local fileoff="$2"
  local elffile="$3"
  local symname="$4"
  local len="$5"
  local value="$6"

  local origvalue="$value"
  local i
  local val
  local vals=""

  local pos=$(i386-elf-nm -t d "$elffile" | \
              awk '{if ($3 == "'"$symname"'") {print $1 + 0}}')
  if [ -z "$pos" ]; then
    echo "$basename: symbol \"$symname\" not found in file $elffile" >&2
    exit 1
  fi

  for i in $(seq 1 $len); do
    val=$((value % 256))
    value=$((value / 256))

    vals="$vals\\$(printf "%o" $val)"
  done
  if [ "$value" -ne 0 ]; then
    echo "$basename: symbol \"$symname\" value is too big for $len bytes:" \
         "\"$origvalue\"" >&2
    exit 1
  fi

  printf "$vals" | dd of="$filenam" bs=1 iflag=fullblock \
                     seek=$((fileoff + pos)) conv=notrunc status=none
}

sfdisk=$(whereis -b sfdisk | awk '{print $2}')
[ -n "$sfdisk" ] || error "no sfdisk found"

# create image file
qemu-img create -q -f raw "$imgfile" "$imgsize"
dd if="$mbrbin" of="$imgfile" bs=512 conv=notrunc status=none

## set_sym "$imgfile" 0 "$mbrelf" beh 1 1

startsec="2048"
psize="20480"
secsize="512"

# create partition table
echo "$startsec,$psize,,*" |
  "$sfdisk" --no-reread --no-tell-kernel --label dos -q "$imgfile"

# create filesystem
case "$fstype" in
  FAT)
    mkfs=$(findex mkfs.fat)
    "$mkfs" --offset "$startsec" "$imgfile" $((psize / 2))
    ;;
  Ext2)
    mkfs=$(findex mkfs.ext2)
    "$mkfs" -E offset=$((startsec * secsize)) "$imgfile" $((psize / 2))k
    ;;
  *)
    error "Bad FS type: \"$fstype\"."
    ;;
esac

# copy boot block
i386-elf-readelf -S "$bootelf" | \
  awk '{
         if ($0 ~ /^ *\[ *[[:digit:]]+\]/) {
           sub(/\[ *[[:digit:]]+\]/,"",$0);
           if ($2 == "PROGBITS") {
             print $3 " " $5
           }
         }
       }' | \
  while read seek count; do
    dd if="$bootbin" of="$imgfile" bs=1 \
      seek=$((startsec * secsize + 0x$seek)) \
      skip=$((0x$seek)) count=$((0x$count)) \
      iflag=fullblock conv=notrunc status=none
  done

# copy loader to filesystem



# set loader start sector and length
set_sym "$imgfile" $((startsec * secsize)) "$bootelf" ldrlba 8 $((65536 + 512))
set_sym "$imgfile" $((startsec * secsize)) "$bootelf" ldrlen 2 257
