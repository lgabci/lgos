#!/bin/sh

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

# find executable file and store in a variable, exit with error if not found
# arguments
#  1. program name to find
#  2. variable name
findex () {
  local progname
  local varname
  local varvalue
  progname="$1"
  varname="$2"
  varvalue=$(eval "echo \${$varname:-}")
  if [ -z "$varvalue" ]; then
    local ret
    ret=$(whereis -b "$progname" | awk '{print $2}')
    if [ -z "$ret" ]; then
      [ -n "$ret" ] || error "findex: $progname not found."
    fi
    eval $varname=$ret
  fi
}

# get BIOS disk ID
getbiosdisk () {
  local disktype

  disktype="$1"

  local biosdisk
  biosdisk=""

  case "$disktype" in
    "fd")
      biosdisk="0x00"
      ;;
    "hd")
      biosdisk="0x80"
      ;;
  esac

  echo "$biosdisk"
}

# get FAT media byte value
# arguments
#  1. disk type: hd, fd
#  2. image size, eg.: 100M
#  3. FS type: FAT, Ext2
getfatmedia () {
  local disktype
  local imgsize
  local fstype

  disktype="$1"
  imgsize="$2"
  fstype="$3"

  local fatmedia
  fatmedia=""

  case "$fstype" in
    FAT)
      case "$disktype" in
        fd)
          case "imgsize" in
            1440K|2880K)
              fatmedia="0xf0"
              ;;
            720K|1200K)
              fatmedia="0xf9"
              ;;
            180K)
              fatmedia="0xfc"
              ;;
            360K)
              fatmedia="0xfd"
              ;;
            160K)
              fatmedia="0xfe"
              ;;
            320K)
              fatmedia="0xff"
              ;;
            *)
              fatmedia="0xf0"
              ;;
          esac
          ;;
        hd)
          fatmedia="0xf8"
          ;;
      esac
      ;;
  esac

  echo "$fatmedia"
}

# get FAT media byte value
# arguments
#  1. disk type: hd, fd
#  2. image size in sectors
#  3. partition size in sectors
#  4. FS type: FAT, Ext2
getfatsize () {
  local disktype
  local imgsizes
  local partsize
  local fstype

  disktype="$1"
  imgsizes="$2"
  partsize="$3"
  fstype="$4"

  local fatsize
  fatsize=""

  local fssize
  case "$disktype" in
    fd)
      fssize="$imgsizes"
      ;;
    hd)
      fssize="$partsize"
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
      if [ "$fssize" -lt 100 ]; then  # < 50 KB
        die "FAT partition size too small: $fssize"
      elif [ "$fssize" -lt 8192 ]; then  # < 4 MB
        fatsize=12
      elif [ "$fssize" -lt 2097152 ]; then    # < 1 GB
        fatsize=16
      elif [ "$fssize" -le 4294967296 ]; then  # <= 2 TB
        fatsize=32
      else
        die "FAT partition size too big: $fssize"
      fi
      ;;
  esac

  echo "$fatsize"
}

# get partition type ID
# arguments
#  1. disk type: hd, fd
#  2. partition start in sectors
#  3. partition size in sectors
#  4. FS type: FAT, Ext2
getparttype () {
  local disktype
  local partstart
  local partsize
  local fstype

  disktype="$1"
  partstart="$2"
  partsize="$3"
  fstype="$4"

  local parttype
  parttype=""

  case "$disktype" in
    hd)
      case "$fstype" in
        Ext2)
          parttype=83
          ;;
        FAT)
          local partend
          partend=$((partstart + partsize - 1))

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
            if [ "$partend" -lt 65536 ]; then       # in 1st 32 MB of disk
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

  echo "$parttype"
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
#  8. MBR bin file
#  9. boot elf file
# 10. boot bin file
# 11. loader elf file
# 12. loader bin file
checkparams () {
  if [ $# -ne 12 ]; then
    die "bad argument list"
  fi

  imgfile="$1"
  disktype="$2"
  imgsize="$3"
  partstart="$4"
  partsize="$5"
  fstype="$6"
  mbrelf="$7"
  mbrbin="$8"
  bootelf="$9"
  bootbin="${10}"
  ldrelf="${11}"
  ldrbin="${12}"

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
    "Ext2"|"FAT")
      true
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
      if [ -n "$mbrelf" ] || [ -n "$mbrbin" ] ; then
        die "no mbr need on a floppy disk"
      fi
      ;;
    "hd")
      if [ -z "$partstart" ] || [ -z "$partsize" ]; then
        die "missing partititon start and/or size on a hard disk"
      fi
      if [ -z "$mbrelf" ] || [ -z "$mbrbin" ] ; then
        die "missing mbr on a hard disk"
      fi
      ;;
    *)
      die "bad disk type: \"$disktype\""
      ;;
  esac

  if [ -z "$bootelf" ] || [ -z "$bootbin" ] ; then
    die "missing boot secor"
  fi

  if [ -z "$ldrelf" ] || [ -z "$ldrbin" ] ; then
    die "missing loader"
  fi

  imgsizes=$(numfmt --from iec --to-unit "$secsize" "$imgsize")
  imgsizek=$(numfmt --from iec --to-unit 1024 "$imgsize")
}

# create image file
# arguments
#  1. image file
#  2. image size (eg. 100M)
createimg () {
  local imgfile
  local imgsizeb
  imgfile="$1"
  imgsizeb="$2"

  if [ -e "$imgfile" ]; then
    truncate -s 0 "$imgfile"
  fi
  truncate -s "$imgsizeb" "$imgfile"
}

# create partition in image file
# arguments
#  1. image file
#  2. disk type: hd, fd
#  3. partition start in sectors
#  4. partition size in sectors
#  5. filesystem type: FAT, Ext2
createpart () {
  local imgfile
  local disktype
  local partstart
  local partsize
  local fstype

  imgfile="$1"
  disktype="$2"
  partstart="$3"
  partsize="$4"
  fstype="$5"

  if [ "$disktype" = "hd" ]; then
    findex sfdisk sfdisk

    local parttype
    parttype=$(getparttype "$disktype" "$partstart" "$partsize" "$fstype")

    echo "$partstart,$partsize,$parttype,*" |
      "$sfdisk" --no-reread --no-tell-kernel --quiet --sector-size "$secsize" \
                --unit S --label dos "$imgfile"
  fi
}

# create file system in image file partition
# arguments
#  1. image file
#  2. partition start in sectors
#  3. partition size in sectors
#  4. filesystem type: FAT, Ext2
createfs () {
  local imgfile
  local disktype
  local partstart
  local partsize
  local fstype
  local partsizek

  imgfile="$1"
  disktype="$2"
  partstart="$3"
  partsize="$4"
  fstype="$5"
  partsizek="$6"

  case "$disktype" in
    fd)
      partstart="0"
      ;;
  esac

  case "$fstype" in
    Ext2)
      findex mkfs.ext2 mkfsext2
      "$mkfsext2" -E offset="$partstart" -q "$imgfile" "$partsizek"
      ;;
    FAT)
      local fatmedia
      local fatsize
      local biosdisk

      fatmedia=$(getfatmedia "$disktype" "$imgsize" "$fstype")
      fatsize=$(getfatsize "$disktype" "$imgsizes" "$partsize" "$fstype")
      biosdisk=$(getbiosdisk "$disktype")

      findex mkfs.fat mkfsfat
      "$mkfsfat" -D "$biosdisk" -F "$fatsize" -M "$fatmedia" -g 255/63 \
                 --offset "$partstart" "$imgfile" ${partsizek:+"$partsizek"}
      ### set CHS geometry of FAT file system
      ;;
  esac
}


checkparams "$@"
createimg "$imgfile" "$imgsize"
createpart "$imgfile" "$disktype" "$partstart" "$partsize" "$fstype"
createfs "$imgfile" "$disktype" "$partstart" "$partsize" "$fstype" "$partsizek"

die -----------------






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
