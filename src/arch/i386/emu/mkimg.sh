#!/bin/sh

# LGOS i386 disk image creator shell script

# +------------------------------------+
# | parameters                         |
# +------+-----------------------------+
# | pos. | value                       |
# +------+-----------------------------+
# |   1. | image file                  |
# |   2. | disk type: hd, fd           |
# |   3. | image size, eg.: 100M       |
# |   4. | partition start in sectors  |
# |   5. | partition size in sectors   |
# |   6. | FS type: FAT, Ext2          |
# |   7. | MBR elf file                |
# |   8. | boot elf file               |
# |   9. | loader elf file             |
# +------+-----------------------------+

# +-----------------------------------------------+
# | global variables                              |
# +-------------+---------------------------------+
# | variable    | value                           |
# +-------------+---------------------------------+
# | imgfile     | image file                      |
# | disktype    | disk type: hd, fd               |
# | imgsize     | image size, eg.: 100M           |
# | partstart   | partition start in sectors      |
# | partsize    | partition size in sectors       |
# | fstype      | FS type: FAT, Ext2              |
# | mbrelf      | MBR elf file                    |
# | bootelf     | boot elf file                   |
# | ldrelf      | loader elf file                 |
# | secsize     | sector size in bytes            |
# | partsizek   | partition size in KB            |
# | imgsizes    | image file size in sectors      |
# | partstartb  | partition start in bytes        |
# | partsizeb   | partition size in bytes         |
# | biosdisk    | BIOS disk ID: fd = 0, hd = 0x80 |
# | fatmedia    | FAT media byte                  |
# | fatsize     | FAT size: 12, 16, or 32         |
# | parttype    | partition ID type               |
# | bootdir     | boot directory in image         |
# | loopdev     | LOOP device of image file       |
# | mountpoint  | mount point of image file       |
# | partend     | partition end in sectors        |
# | mcyl        | number of cylinders, only FDD   |
# | mhead       | number of heads, only FDD       |
# | msec        | number of sectors, only FDD     |
# +-------------+---------------------------------+

set -eu
export LANG=C

basename=$(basename "$0")

# print error message and exit with 1 exit status
# arguments
#  1. message
die () {
  echo "$basename: $1" >&2
  exit 1
}

# exit function
# called on trap
exitfv () {
  trap - EXIT HUP INT QUIT TERM

  umountfs "${mountpoint:-}" "${loopdev:-}"
}
trap exitfv EXIT HUP INT QUIT TERM

# find executable file and return it, exit with error if not found
# arguments
#  1. program name to find
findex () {
  _progname="$1"

  _ret=$(whereis -b "$_progname" | awk '{print $2}')
  if [ -z "$_ret" ]; then
    die "findex: $_progname not found."
  fi
  echo "$_ret"
  unset _ret

  unset _progname
}

# copy and ELF file to the image, max size is 512 bytes
# arguments
#  1. ELF file
#  2. file to copy to
#  3. offset in image file
#  4. max size of code
copyelf () {
  _elf="$1"
  _img="$2"
  _imgoffs="${3:-0}"
  _maxsz="${4:-0}"

  x86_64-elf-readelf --section-headers --wide "$_elf" | \
    awk -F '[ \t\[\]]+' \
        '{ if ( $2 ~ /^[0-9]+$/ && $4 == "PROGBITS" && $9 ~ /A/ )
           { print $5, $6, $7} }' | \
    while read -r _addr _offs _size; do
      _addr=$((0x$_addr))
      _offs=$((0x$_offs))
      _size=$((0x$_size))

      if [ "$_size" -ne 0 ]; then
        if [ "$_maxsz" -gt 0 ] && [ $((_addr + _size)) -gt "$_maxsz" ]; then
          die "copyelf ($_elf) is over maximum size ($_maxsz) bytes."
        fi
        dd if="$_elf" of="$_img" bs=1 skip="$_offs" \
           seek="$((_imgoffs + _addr))" count="$_size" conv=notrunc \
           iflag=fullblock status=none
      fi

    done

  unset _elf
  unset _img
  unset _imgoffs
  unset _maxsz
}

# get symbol address from anf ELF file
# arguments
#  1. ELF file
#  2. symbol name
getsymaddr () {
  _elf="$1"
  _sym="$2"

  _addr=$(x86_64-elf-readelf --symbols "$_elf" | \
            awk -F '[ :]+' \
                '{ if ( $2 ~ /^[0-9]+$/ && $9 == "'"$_sym"'" ) { print $3 }}' )
  if [ -z "$_addr" ]; then
    die "getsymaddr: symbol ($_sym) not found in $_elf."
  fi
  _addr=$((0x$_addr))

  echo "$_addr"

  unset _elf
  unset _sym
  unset _addr
}

# get symbol value in anf ELF file
# arguments
#  1. ELF file
#  2. binary file
#  3. symbol name
#  4. value
#  5. length in bytes
#  6. offset in byte from start of file (eg. boot sector in image), defaul 0
setsymval () {
  _elf="$1"
  _bin="$2"
  _sym="$3"
  _val="$4"
  _len="$5"
  _offs="${6:-0}"

  _addr=$(getsymaddr "$_elf" "$_sym")
  _v="$_val"
  _valstr=""
  for i in $(seq 1 "$_len"); do
    _valstr="$(printf "\\x%02x" "$((_v % 256))")$_valstr"
    _v=$((_v / 256))
  done
  if [ "$_v" -ne 0 ]; then
    die "setsymval: value ($_val) is too big to fit in $_len bytes."
  fi
  unset _v
  printf "$_valstr" | \
    dd of="$_bin" bs=1 seek="$((_offs + _addr))" conv=notrunc status=none
  unset _valstr

  unset _elf
  unset _bin
  unset _sym
  unset _val
  unset _len
  unset _offs
}

# check parameters
# arguments
#  1. image file
#  2. disk type: hd, fd
#  3. image size, eg.: 100M
#  4. partition start in sectors
#  5. partition size in sectors
#  6. FS type: FAT, Ext2
#  7. MBR elf file
#  8. boot elf file
#  9. loader elf file

checkparams () {
  if [ $# -ne 9 ]; then
    die "bad argument list"
  fi

  imgfile="$1"
  disktype="$2"
  imgsize="$3"
  partstart="$4"
  partsize="$5"
  fstype="$6"
  mbrelf="$7"
  bootelf="$8"
  ldrelf="$9"

  secsize="512"
  if [ -n "$partsize" ]; then
    partsizek=$((partsize / 2))  # partition size in KB
  else
    partsizek=""
  fi

  if [ -z "$imgfile" ]; then
    die "missing image file name"
  fi

  if [ -z "$imgsize" ]; then
    die "missing image size"
  fi

  case "$fstype" in
    "FAT")
      mfstype="vfat"
      ;;
    "Ext2")
      mfstype="ext2"
      ;;
    *)
      die "bad fs type: \"$fstype\""
      ;;
  esac

  case "$disktype" in
    "fd")
      if [ -n "$partstart" ] || [ -n "$partsize" ]; then
        die "can not create partition on a floppy disk"
      fi
      if [ -n "$mbrelf" ] ; then
        die "no mbr need on a floppy disk"
      fi
      ;;
    "hd")
      if [ -z "$partstart" ] || [ -z "$partsize" ]; then
        die "missing partititon start and/or size on a hard disk"
      fi
      if [ -z "$mbrelf" ] ; then
        die "missing mbr on a hard disk"
      fi
      ;;
    *)
      die "bad disk type: \"$disktype\""
      ;;
  esac

  if [ -z "$bootelf" ] ; then
    die "missing boot secor"
  fi

  if [ -z "$ldrelf" ] ; then
    die "missing loader"
  fi

  imgsizes=$(numfmt --from iec --to-unit "$secsize" "$imgsize")
  partstartb=$((partstart * secsize))
  partsizeb=$((partsize * secsize))

  case "$disktype" in
    "fd")
      biosdisk="0x00"
      ;;
    "hd")
      biosdisk="0x80"
      ;;
  esac

  case "$fstype" in
    FAT)
      case "$disktype" in
        fd)
          case "$imgsize" in
            2880K)
              fatmedia="0xf0"
              mcyl=80
              mhead=2
              msec=36
              ;;
            1440K)
              fatmedia="0xf0"
              mcyl=80
              mhead=2
              msec=18
              ;;
            1200K)
              fatmedia="0xf9"
              mcyl=80
              mhead=2
              msec=15
              ;;
            720K)
              fatmedia="0xf9"
              mcyl=80
              mhead=2
              msec=9
              ;;
            180K)
              fatmedia="0xfc"
              mcyl=40
              mhead=1
              msec=9
              ;;
            360K)
              fatmedia="0xfd"
              mcyl=40
              mhead=2
              msec=9
              ;;
            160K)
              fatmedia="0xfe"
              mcyl=40
              mhead=1
              msec=8
              ;;
            320K)
              fatmedia="0xff"
              mcyl=40
              mhead=2
              msec=8
              ;;
            *)
              die "Unknown floppy disk size: $imgsize."
              ;;
          esac
          ;;
        hd)
          fatmedia="0xf8"
          ;;
      esac
      ;;
  esac

  case "$disktype" in
    fd)
      _fssize="$imgsizes"
      ;;
    hd)
      _fssize="$partsize"
      ;;
  esac

  case "$fstype" in
    FAT)
      # FAT12: 50 KB - 16 MB min - max
      #        50 KB - 4 MB - 1
      # FAT16: 2 MB - 4 GB min - max
      #        4 MB - 1 GB - 1
      # FAT32: 512 MB - 2 TB
      #        1 GB - 2TB
      if [ "$_fssize" -lt 100 ]; then  # < 50 KB
        die "FAT partition size too small: $_fssize"
      elif [ "$_fssize" -lt 8192 ]; then  # < 4 MB
        fatsize=12
      elif [ "$_fssize" -lt 2097152 ]; then    # < 1 GB
        fatsize=16
      elif [ "$_fssize" -le 4294967296 ]; then  # <= 2 TB
        fatsize=32
      else
        die "FAT partition size too big: $_fssize"
      fi
      ;;
  esac
  unset _fssize

  partend=$((partstart + partsize - 1))

  case "$disktype" in
    hd)
      case "$fstype" in
        Ext2)
          parttype=83
          ;;
        FAT)
          # FAT12: 50 KB - 16 MB min - max
          #        50 KB - 4 MB - 1
          #        0x01 in 1st 32 MB of disk
          #        0x06 over 1st 32 MB of disk
          # FAT16: 2 MB - 4 GB min - max
          #        4 MB - 1 GB - 1
          #        0x04 size < 65536 sectors, in 1st 32 MB of disk
          #        0x06 size >= 65536 sectors, in 1st 8 GB of disk
          #        0x0E over 1st 8 GB of disk, LBA
          # FAT32: 512 MB - 2 TB min - max
          #        1 GB - 2TB
          #        0x0B CHS
          #        0x0C LBA
          if [ "$partsize" -lt 100 ]; then  # < 50 KB
            die "FAT partition size too small: $partsize"
          elif [ "$partsize" -lt 8192 ]; then  # < 4 MB
            if [ "$partend" -lt 65536 ]; then  # in 1st 32 MB of disk
              parttype="01"
            else                               # over 1st 32 MB of disk
              parttype="06"
            fi
          elif [ "$partsize" -lt 2097152 ]; then    # < 1 GB
            if [ "$partend" -lt 65536 ]; then      # in 1st 32 MB of disk
              parttype="04"
            elif [ "$partend" -lt 16777216 ]; then  # in 1st 8 GB of disk
              parttype="06"
            else                                    # over 1st 8 GB of disk
              parttype="0E"
            fi
          elif [ "$partsize" -le 4294967296 ]; then  # <= 2 TB
            parttype="0C"
          else
            die "FAT partition size too big: $partsize"
          fi
          ;;
      esac
      ;;
  esac

  bootdir="boot"
}

# create image file
createimg () {
  if [ -e "$imgfile" ]; then
    truncate -s 0 "$imgfile"
  fi
  truncate -s "$imgsize" "$imgfile"
}

# create partition in image file
createpart () {
  if [ "$disktype" = "hd" ]; then
    sfdisk=$(findex "sfdisk")

    echo "$partstart,$partsize,$parttype,*" |
      "$sfdisk" --no-reread --no-tell-kernel --quiet --sector-size "$secsize" \
                --unit S --label dos "$imgfile"
  fi
}

# create MBR sector
creatembr () {
  case "$disktype" in
    hd)
      copyelf "$mbrelf" "$imgfile" 0 "$secsize"
      ;;
  esac
}

# create file system in image file partition
createfs () {
  case "$disktype" in
    fd)
      partstart="0"
      ;;
  esac

  case "$fstype" in
    Ext2)
      mkfsext2=$(findex "mkfs.ext2")
      "$mkfsext2" -E offset="$partstart" -q "$imgfile" "$partsizek"
      ;;
    FAT)
      mkfsfat=$(findex "mkfs.fat")
      "$mkfsfat" -D "$biosdisk" -F "$fatsize" -M "$fatmedia" -g 255/63 \
                 --offset "$partstart" "$imgfile" ${partsizek:+"$partsizek"}
      ### set CHS geometry of FAT file system
      ;;
  esac
}

# create boot sector
createboot () {
  copyelf "$bootelf" "$imgfile" "$partstartb" "$secsize"

  case "$disktype" in
    fd)
      setsymval "$bootelf" "$imgfile" mcyl "$mcyl" 2 "$partstartb"
      setsymval "$bootelf" "$imgfile" mhead "$mhead" 2 "$partstartb"
      setsymval "$bootelf" "$imgfile" msec "$msec" 2 "$partstartb"
      ;;
  esac
}

# mount file system
mountfs () {
  case "$disktype" in
    fd)
      _udisksctlout=$(udisksctl loop-setup --file "$imgfile" \
                                --no-user-interaction --no-partition-scan)
      ;;
    hd)
      _udisksctlout=$(udisksctl loop-setup --file "$imgfile" \
                              --offset "$partstartb" \
                              --size "$partsizeb" \
                              --no-user-interaction --no-partition-scan)
      ;;
  esac

  loopdev=$(echo "$_udisksctlout" | grep -o '/dev/loop[0-9]\+')
  if [ -z "$loopdev" ]; then
    die "the name of the loop device not found: \"$_udisksctlout\""
  fi
  # test if the loopdev is mounted (automount) and mount if it is not
  if ! mountpoint=$(findmnt --noheading -o TARGET --source "$loopdev"); then
    udisksctlout=$(udisksctl mount --block-device "$loopdev" \
                             --filesystem-type "$mfstype" \
                             --no-user-interaction)
    mountpoint=$(echo "$udisksctlout" | grep -o '/media/'"$USER"'/[^ ]\+')
    if [ -z "$mountpoint" ]; then
      die "the name of the mount point not found: \"$udisksctlout\""
    fi
  fi

  unset _udisksctlout
}

# umount file system, call by exitfv
umountfs () {
  if [ -n "${mountpoint:-}" ] &&
       findmnt --noheading -o TARGET --target "$mountpoint" >/dev/null; then
    udisksctl unmount --block-device "$loopdev" \
              --no-user-interaction >/dev/null
  fi

  if [ -n "${loopdev:-}" ]; then
    losetup=$(findex "losetup")
    if "$losetup" "$loopdev" >/dev/null 2>&1; then
      udisksctl loop-delete --block-device "$loopdev" \
                --no-user-interaction >/dev/null
    fi
  fi
}

# copy loader to image
copyldr () {
  mkdir -p "$mountpoint/$bootdir"
  copyelf "$ldrelf" "$mountpoint/$bootdir/loader.bin"  ###

  echo "bootdir: $bootdir" >&2       ###
  ls -la "$mountpoint/$bootdir" >&2  ###
  ls -la "$ldrelf" >&2               ###

  echo "--------------------------------------"  ###
  filefrag=$(findex "filefrag")
  "$filefrag" -b"$secsize" -e -s -v "$mountpoint/$bootdir/loader.bin" ###
  echo "--------------------------------------"  ###

}

# main function
# arguments
#  1. image file
#  2. disk type: hd, fd
#  3. image size, eg.: 100M
#  4. partition start in sectors
#  5. partition size in sectors
#  6. FS type: FAT, Ext2
#  7. MBR elf file
#  8. MBR bin file
#  9. boot elf file
# 10. boot bin file
# 11. loader elf file
# 12. loader bin file
main () {
  checkparams "$@"
  createimg
  createpart
  creatembr
  createfs
  createboot
  mountfs

  copyldr
  exitfv

##  die -----------------
}

main "$@"



: <<'END_COMMENT'

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
exitfv_ () {
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
END_COMMENT
