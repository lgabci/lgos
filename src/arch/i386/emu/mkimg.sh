#!/bin/sh

# arguments
#  1. image file
#  2. disk type: hd, fd
#  3. image size, part start and size in sectors, eg.: 100M,2048,20480
#  4. FS type: FAT, Ext2
#  5. MBR elf file
#  6. MBR bin file
#  7. boot elf file
#  8. boot bin file
#  9. loader elf file
# 10. loader bin file

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
    error "$basename: symbol \"$symname\" not found in file $elffile"
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
  [ -n "$pos" ] || exit 1
  setfvalue "$filename" "$symname" "$((fileoff + pos))" "$len" "$value"
}

# write file fragment blocklist into a file
# parameters: 1. file
#             2. file to write fragment list into
#             3. variable name to write fragment numbers into it
#             4. size limit in block numbers
#             5. filesystem offset in sectors on physical disk, optional
# output:     number of blocks in blocklist
wrtfilefrag() {
  local fname="$1"
  local fragfile="$2"
  local fragvar_="$3"
  local sizelim="$4"
  local fsoffs="${5:-0}"

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
  pos=0
  while read num; do
    if [ -n "$fragvar_" ]; then
      eval "$fragvar_=\"\${$fragvar_:-} \$((num + fsoffs))\""
    else
      setfvalue "$fragfile" "fragment" "$pos" 4 $((num + fsoffs))
    fi
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

  trap - EXIT INT
}
trap exitfv EXIT INT

if [ $# -ne 10 ]; then
  echo "$basename: bad argument list" >&2
  echo "\t$@" >&2
  exit 1
fi

imgfile=$(realpath "$1")
disktype="$2"
IFS=, read -r imgsize pstart psize <<EOF
$3
EOF
fstype="$4"
mbrelf=${5:+$(realpath "$5")}
mbrbin=${6:+$(realpath "$6")}
bootelf=$(realpath "$7")
bootbin=$(realpath "$8")
loaderelf=$(realpath "$9")
loaderbin=$(realpath "${10}")

secsize="512"

sfdisk=$(whereis -b sfdisk | awk '{print $2}')
[ -n "$sfdisk" ] || error "no sfdisk found"

# create image file
qemu-img create -q -f raw "$imgfile" "$imgsize"
case "$disktype" in
  hd)
    dd if="$mbrbin" of="$imgfile" bs="$secsize" conv=notrunc status=none

    # create partition table
    echo "$pstart,$psize,,*" |
      "$sfdisk" --no-reread --no-tell-kernel --label dos -q "$imgfile"
    ;;
  fd)
    pstart=0
    ;;
  *)
    error "Unknown disk type: $disktype"
    ;;
esac

# create filesystem
case "$fstype" in
  Ext2)
    mkfs=$(findex mkfs.ext2)
    case "$disktype" in
      hd)
        mkopts="offset=$((pstart * secsize))"
        mkopts="$mkopts,root_owner=$(id -u $USER):$(id -g $USER)"
        "$mkfs" -E "$mkopts" "$imgfile" $((psize / 2))k >/dev/null
        ;;
      fd)
        mkopts="root_owner=$(id -u $USER):$(id -g $USER)"
        "$mkfs" -E "$mkopts" "$imgfile" >/dev/null
        ;;
    esac
    ;;
  FAT)
    mkfs=$(findex mkfs.fat)
    case "$disktype" in
      hd)
        "$mkfs" --offset "$pstart" "$imgfile" $((psize / 2)) >/dev/null
        ;;
      fd)
        "$mkfs" "$imgfile" >/dev/null
        ;;
    esac
    ;;
  *)
    error "Unknown filesystem type: $fstype."
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
      seek=$((pstart * secsize + 0x$seek)) \
      skip=$((0x$seek)) count=$((0x$count)) \
      iflag=fullblock conv=notrunc status=none
  done

# copy loader to filesystem
mountpt="$imgfile.mnt"
bootdir="boot"

mkdir -p "$mountpt"
case "$fstype" in
  Ext2)
    mountopts="-t ext2 -o loop"
    case "$disktype" in
      hd)
        mountopts="$mountopts,offset=$((pstart * secsize))"
        mountopts="$mountopts,sizelimit=$((psize * secsize))"
        ;;
      fd)
        ;;
    esac
    ;;
  FAT)
    mountopts="-t msdos -o loop"
    case "$disktype" in
      hd)
        mountopts="$mountopts,offset=$((pstart * secsize))"
        mountopts="$mountopts,sizelimit=$((psize * secsize))"
        mountopts="$mountopts,uid=$USER,gid=$USER"
        ;;
      fd)
        mountopts="$mountopts,uid=$USER,gid=$USER"
        ;;
    esac
    ;;
esac
sudo mount $mountopts "$imgfile" "$mountpt"

mkdir -p "$mountpt/$bootdir"
cp "$loaderbin" "$mountpt/$bootdir/"

filefrag=$(findex filefrag)

# file blocklist of loader
ldrbin="$mountpt/$bootdir/$(basename $loaderbin)"
ldrbinfrag="${ldrbin%.*}.frg"
blklen=$(wrtfilefrag "$ldrbin" "$ldrbinfrag" "" $((secsize / 4)) "$pstart")

# file blocklist of blocklist file
wrtfilefrag "$ldrbinfrag" "" fragvar 1 "$pstart" >/dev/null
fragvar="$((fragvar + fsoffs))"
sudo umount "$mountpt"

# file blocklist length of blocklist file to boot sector
setsym "$imgfile" $((pstart * secsize)) "$bootelf" ldrlba 4 "$fragvar"
setsym "$imgfile" $((pstart * secsize)) "$bootelf" ldrlen 2 "$blklen"

# set CHS for floppy
case "$disktype" in
  fd)
    case "$imgsize" in
      160K)
        mcyl=40
        mhead=1
        msec=8
        ;;
      360K)
        mcyl=40
        mhead=2
        msec=9
        ;;
      1200K)
        mcyl=80
        mhead=2
        msec=15
        ;;
      720K)
        mcyl=80
        mhead=2
        msec=9
        ;;
      1440K)
        mcyl=80
        mhead=2
        msec=18
        ;;
      *)
        error "Bad floppy disk size: $imgsize."
        ;;
    esac

    setsym "$imgfile" $((pstart * secsize)) "$bootelf" mcyl 2 "$mcyl"
    setsym "$imgfile" $((pstart * secsize)) "$bootelf" mhead 2 "$mhead"
    setsym "$imgfile" $((pstart * secsize)) "$bootelf" msec 2 "$msec"
    ;;
esac
