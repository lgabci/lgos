#!/bin/sh
set -eu

basename=$(basename $0)

error() {
  echo "$basename: $1" >&2
  exit 1
}

if [ $# -ne 6 ]; then
  echo "$basename: bad argument list" >&2
  echo "\t$@" >&2
  exit 1
fi

imgfile="$1"
imgsize="$2"
mbrelf="$3"
mbrbin="$4"
loaderelf="$5"
loaderbin="$6"

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

set_sym "$imgfile" 0 "$mbrelf" beh 1 1

# create partition table
echo ',20M,,*' |
  "$sfdisk" --no-reread --no-tell-kernel --label dos -q "$imgfile"
