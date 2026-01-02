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

# +------------------------------------------------+
# | global variables                               |
# +-------------+----------------------------------+
# | variable    | value                            |
# +-------------+----------------------------------+
# | basename    | basename of this script          |
# | basedir     | directory of this script         |
# | imgfile     | image file                       |
# | disktype    | disk type: hd, fd                |
# | imgsize     | image size, eg.: 100M            |
# | partstart   | partition start in sectors       |
# | partsize    | partition size in sectors        |
# | fstype      | FS type: FAT, Ext2               |
# | mbrelf      | MBR elf file                     |
# | bootelf     | boot elf file                    |
# | ldrelf      | loader elf file                  |
# | secsize     | sector size in bytes             |
# | partsizek   | partition size in KB             |
# | imgsizes    | image file size in sectors       |
# | partstartb  | partition start in bytes         |
# | partsizeb   | partition size in bytes          |
# | biosdisk    | BIOS disk ID: fd = 0, hd = 0x80  |
# | fatmedia    | FAT media byte                   |
# | parttype    | partition ID type                |
# | bootdir     | boot directory in image          |
# | ldrbin      | loader bin file, without path    |
# | ldrblk      | loader blocklist file            |
# | loopdev     | LOOP device of image file        |
# | mountpoint  | mount point of image file        |
# | partend     | partition end in sectors         |
# | mcyl        | number of cylinders, only FDD    |
# | mhead       | number of heads, only FDD        |
# | msec        | number of sectors, only FDD      |
# | mfstype     | FS type for udisksctl: vfat/ext2 |
# +-------------+----------------------------------+

set -eu
export LANG=C

basename=$(basename "$0")
basedir=$(dirname "$0")

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
  err="$?"
  trap - EXIT HUP INT QUIT TERM

  umountfs

  if [ $err -ne 0 ]; then
    rm -f "$imgfile"
  fi
}
trap exitfv EXIT HUP INT QUIT TERM

# convert a decimal value to octal value
# arguments
#  1. value
#  2. length in bytes
tooct () {
  _val="$1"
  _len="$2"

  _v="$_val"
  _valstr=""
  for _i in $(seq 1 "$_len"); do
    _valstr="$_valstr\\$(printf "%o" "$((_v % 256))")"
    _v=$((_v / 256))
  done

  if [ "$_v" -ne 0 ]; then
    die "tooct: value ($_val) is too big to fit in $_len bytes."
  fi

  printf "%s" "$_valstr"
}

# get user ID
getuid () {
  id --user
}

# get group ID
getgid () {
  id --group
}

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
}

# copy and ELF file to the image
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
    awk -F '[ \t[]]+' \
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
}

# get symbol address from an ELF file
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
}

# set symbol value in an ELF file
# arguments
#  1. ELF file
#  2. binary file
#  3. symbol name
#  4. value
#  5. length in bytes
#  6. offset in byte from start of file (eg. boot sector in image), default 0
setsymval () {
  _elf="$1"
  _bin="$2"
  _sym="$3"
  _val="$4"
  _len="$5"
  _offs="${6:-0}"

  _addr=$(getsymaddr "$_elf" "$_sym")
  _valstr=$(tooct "$_val" "$_len")

  printf "$_valstr" | \
    dd of="$_bin" bs=1 seek="$((_addr + _offs))" conv=notrunc status=none
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
      break
      ;;
    "Ext2")
      mfstype="ext2"
      break
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

      partstartb=$((partstart * secsize))
      partsizeb=$((partsize * secsize))
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

  partend=$((partstart + partsize - 1))

  case "$disktype" in
    hd)
      case "$fstype" in
        Ext2)
          parttype=83
          ;;
        FAT)
          parttype="0c"
          ;;
      esac
      ;;
  esac

  bootdir="boot"
  ldrbin="$(basename -s .elf "$ldrelf").bin"
  ldrblk="$(basename -s .elf "$ldrelf").blk"
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
      ### ezt lehet korábban kellene nullázni
      partstart="0"
      ;;
  esac

  case "$fstype" in
    Ext2)
      mkfsext2=$(findex "mkfs.ext2")
      "$mkfsext2" -E offset="$partstartb,root_owner=$(getuid):$(getgid)" \
                  -q "$imgfile" "$partsizek"k
      ;;
    FAT)
      mkfsfat=$(findex "mkfs.fat")
      _mkfsfatout=$("$mkfsfat" -D "$biosdisk" -M "$fatmedia" \
                               ${mhead:+${msec:+-g "$mhead/$msec"}} \
                               --offset "$partstart" -v --mbr=yes "$imgfile" \
                               ${partsizek:+"$partsizek"})

      case "$disktype" in  # set partition type, it was 0c (FAT32 LBA)
        hd)
          _fatsize=$(echo "$_mkfsfatout" | \
                       sed -n 's/.* \(12\|16\|32\)-bit FATs.*/\1/p')

          if [ -n "$_fatsize" ]; then
            _parttype=""
            case "$_fatsize" in
              12)
                if [ "$partend" -le 65535 ]; then
                  _parttype=01
                else
                  _parttype=06
                fi
                ;;
              16)
                if [ "$partend" -le 65535 ]; then
                  _parttype=04
                elif [ "$partend" -le 16450560 ]; then  # 63 * 255 * 1024
                  _parttype=06
                else
                  _parttype=0e
                fi
                ;;
            esac

            if [ -n "$_parttype" ]; then
              "$sfdisk" --no-reread --no-tell-kernel --quiet \
                        --sector-size "$secsize" --unit S --label dos \
                        --part-type "$imgfile" 1 "$_parttype"
            fi
          fi
      esac
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
      _opts="loop"
      ;;
    hd)
      _opts="loop,offset=$partstartb,sizelimit=$partsizeb"
      ;;
  esac

  case "$mfstype" in
    vfat)
      _opts="$_opts,uid=$(getuid),gid=$(getgid)"
      ;;
  esac

  mountpoint="$imgfile.mnt"
  mkdir -p "$mountpoint"
  sudo mount -t "$mfstype" -o "$_opts" "$imgfile" "$mountpoint"

  unset _opts
}

# umount file system, call by exitfv
umountfs () {
  if [ -n "${mountpoint:-}" ]; then
    if findmnt --mountpoint "$mountpoint" >/dev/null; then
      sudo umount "$mountpoint"
    fi
  fi
}

# write blocklist of a file on the image file into a file
# arguments
#  1. file
#  2. blocklist file
#  3. max size of blocklist
#  4. offset in blocklist file in bytes, default = 0
writeblklist() {
  _file="$1"
  _blkfile="$2"
  _maxsize="$3"
  _offs="${4:-0}"


  protfile=$(echo "$_file" | sed -e 's/[]\/$*.^[]/\\&/g')

  inode=$(LC_ALL=C fls -f "$mfstype" -F -r -i raw -o "$partstart" \
                   -b "$secsize" "$imgfile" | \
            sed -n "s/^r\/r \([[:digit:]]\+\):[ \t]\+$protfile/\1/p")

  if [ -z "$inode" ]; then
    die "writeblklist: file ($_file) not found in image ($imgfile)."
  fi

  fdetails=$(LC_ALL=C istat -f "$mfstype" -b "$secsize" -o "$partstart" \
                      -i raw "$imgfile" "$inode" | \
               sed -e '1,/Sectors:/d;s/ \+/\n/g')

  if [ -z "$fdetails" ]; then
    die "writeblklist: can not get blocklist for ($file) in ($imgfile)."
  fi

  i=0
  echo "$fdetails" | \
    while read -r a; do
      if [ -n "$a" ] && [ "$a" -gt 0 ]; then
        i=$((i + 1))
        if [ "$i" -gt "$_maxsize" ]; then
          die "copyldr: too big file: $_file."
        fi
        a=$((a + partstart))
        printf "$(tooct "$a" 4)"
      fi
    done | \
      dd of="$_blkfile" seek="$_offs" oflag=seek_bytes conv=notrunc \
         status=none
}


# copy loader to image
copyldr () {
  mkdir -p "$mountpoint/$bootdir"
  copyelf "$ldrelf" "$mountpoint/$bootdir/$ldrbin"

  writeblklist "$bootdir/$ldrbin" "$mountpoint/$bootdir/$ldrblk" 64
##  umountfs

  _offs=$(getsymaddr "$bootelf" ldrlba)
  writeblklist "$bootdir/$ldrblk" "$imgfile" 1 $((partstartb + _offs))

  setsymval "$bootelf" "$imgfile" ldrlen 18 4 "$partstartb"  ###
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
}

main "$@"
