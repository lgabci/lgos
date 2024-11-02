#!/bin/sh
set -eu
export LANG=C

basename=$(basename "$0")

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

# get symbol address
# parameters: 1. elf file
#             2. symbol name
getsymaddr() {
  local elffile="$1"
  local symname="$2"

  local pos=$(i386-elf-nm -t d "$elffile" | \
              awk '{if ($3 == "'"$symname"'") {print $1 + 0}}')
  if [ -z "$pos" ]; then
    echo "$basename: symbol \"$symname\" not found in file $elffile" >&2
    exit 1
  fi

  echo "$pos"
}

# set value in a file
# parameters: 1. file
#             2. symbol name, just for error message
#             3. symbol pos in file
#             3. symbol lenght
#             4. value
setfvalue() {
  local filenam="$1"
  local symname="$2"
  local pos="$3"
  local len="$4"
  local value="$5"

  local origvalue="$value"
  local i
  local val
  local vals=""

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

  printf "$vals" | \
    dd of="$filenam" bs=1 iflag=fullblock seek="$pos" conv=notrunc status=none
}

# set symbol value
# parameters: 1. img file
#             2. elf file offset in img file
#             3. elf file
#             4. symbol name
#             5. symbol lenght
#             6. value
setsym() {
  local filename="$1"
  local fileoff="$2"
  local elffile="$3"
  local symname="$4"
  local len="$5"
  local value="$6"

  local pos=$(getsymaddr "$elffile" "$symname")
  setfvalue "$filename" "$symname" "$((fileoff + pos))" "$len" "$value"
}

# write file fragment blocklist into a file
# parameters: 1. file
#             2. file to write fragment list into
#             3. size limit in block numbers
#             4. filesystem offset in sectors on physical disk, optional
#             5. starting byte position in file, optional
# output:     number of blocks in blocklist
wrtfilefrag() {
  local fname="$1"
  local fragfile="$2"
  local sizelim="$3"
  local fsoffs="${4:-0}"
  local startpos="${5:-0}"

  local tmpf=$(mktemp)
  rmfiles="$rmfiles $tmpf"

  sudo "$filefrag" -b"$secsize" -es "$fname" |
    awk 'BEGIN {
           sizelim = '"$sizelim"'
           secsize='"$secsize"'
         }

         function error(msg) {
           print msg >> "/dev/stderr"
           exit 1
         }

         {
           if ($0 ~ /^File size of/) {
             sub(/ *\(.*$/, "", $0)
             fsize=$NF
           }
           else if ($1 ~ /^[[:digit:]]+:$/) {
             if (fsize == "") {
               error("wrtfilefrag: '"$fname"', can not find file size.")
             }
             sub(/\.\./, "", $4)
             sub(/:/, "", $5)
             count = 0
             for (i = $4 + 0; i <= $5 + 0 && \
               count < int((fsize + secsize - 1) / secsize); i ++) {
               print i
               count ++
               if (sizelim > 0 && count > sizelim) {
                 error("wrtfilefrag: '"$fname"' file size is bigger than '"\
$((sizelim * secsize))"' bytes.")
               }
             }
           }
         }' >"$tmpf"

  local cnt=0
  pos="$startpos"
  while read num; do
    setfvalue "$fragfile" "fragment" "$pos" 4 $((num + fsoffs))
    pos=$((pos + 4))
    cnt=$((cnt + 1))
  done <"$tmpf"

  echo "$cnt"
}

rmfiles=""
# exit function
exitfv () {
  if [ -n "${mountpt:-}" ]; then
    if findmnt "$mountpt" >/dev/null; then
      sudo umount "$mountpt"
    fi
    if [ -d "$mountpt" ]; then
      rm -rf "$mountpt"
    fi
  fi
  [ -n "$rmfiles" ] && rm -f "$rmfiles"
}
trap exitfv EXIT

if [ $# -ne 9 ]; then
  echo "$basename: bad argument list" >&2
  echo "\t$@" >&2
  exit 1
fi

imgfile=$(realpath "$1")
fstype="$2"
imgsize="$3"
mbrelf=$(realpath "$4")
mbrbin=$(realpath "$5")
bootelf=$(realpath "$6")
bootbin=$(realpath "$7")
loaderelf=$(realpath "$8")
loaderbin=$(realpath "$9")

startsec="2048"
psize="20480"
secsize="512"


sfdisk=$(whereis -b sfdisk | awk '{print $2}')
[ -n "$sfdisk" ] || error "no sfdisk found"

# create image file
qemu-img create -q -f raw "$imgfile" "$imgsize"
dd if="$mbrbin" of="$imgfile" bs="$secsize" conv=notrunc status=none

# create partition table
echo "$startsec,$psize,,*" |
  "$sfdisk" --no-reread --no-tell-kernel --label dos -q "$imgfile"

# create filesystem
case "$fstype" in
  FAT)
    mkfs=$(findex mkfs.fat)
    "$mkfs" --offset "$startsec" "$imgfile" $((psize / 2)) >/dev/null
    ;;
  Ext2)
    mkfs=$(findex mkfs.ext2)
    mkopts="offset=$((startsec * secsize))"
    mkopts="$mkopts,root_owner=$(id -u $USER):$(id -g $USER)"
    "$mkfs" -E "$mkopts" "$imgfile" $((psize / 2))k >/dev/null
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
mountpt="$imgfile.mnt"
bootdir="boot"

mkdir -p "$mountpt"
case "$fstype" in
  FAT)
    mountopts="loop,offset=$((startsec * secsize))"
    mountopts="$mountopts,sizelimit=$((psize * secsize))"
    mountopts="$mountopts,uid=$USER,gid=$USER"
    sudo mount -t msdos -o "$mountopts" "$imgfile" "$mountpt"
    ;;
  Ext2)
    mountopts="loop,offset=$((startsec * secsize))"
    mountopts="$mountopts,sizelimit=$((psize * secsize))"
    sudo mount -t ext2 -o "$mountopts" "$imgfile" "$mountpt"
    ;;
esac

mkdir -p "$mountpt/$bootdir"
cp "$loaderbin" "$mountpt/$bootdir/"

filefrag=$(findex filefrag)

# file blocklist of loader
ldrbin="$mountpt/$bootdir/$(basename $loaderbin)"
blklen=$(wrtfilefrag "$ldrbin" "$ldrbin.frag" $((secsize / 4)) "$startsec")

# file blocklist of blocklist file
ldrlbapos=$(getsymaddr "$bootelf" "ldrlba")
wrtfilefrag "$ldrbin.frag" "$imgfile" 1 "$startsec" \
  $((startsec * secsize + ldrlbapos)) >/dev/null

# file blocklist length of blocklist file
setsym "$imgfile" $((startsec * secsize)) "$bootelf" ldrlen 2 "$blklen"
