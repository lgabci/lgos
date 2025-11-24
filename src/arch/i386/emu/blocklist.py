# LGOS i386: get blocklist from emulator disk image

# parameters:
#  1. image file
#  2. file in the image file
#  3. filesystem type, FAT/Ext2
#  4. filesystem offset in sectors

import sys
import struct

# FAT BPB
# B unsigned char  1
# H unsigned short 2
# I unsigned int   4

# Sec offs 	BPB off 	Description
# 0x00B 	0x00 	WORD 	Bytes per logical sector
# 0x00D 	0x02 	BYTE 	Logical sectors per cluster
# 0x00E 	0x03 	WORD 	Reserved logical sectors
# 0x010 	0x05 	BYTE 	Number of FATs
# 0x011 	0x06 	WORD 	Root directory entries
# 0x013 	0x08 	WORD 	Total logical sectors
# 0x015 	0x0A 	BYTE 	Media descriptor
# 0x016 	0x0B 	WORD 	Logical sectors per FAT

# 0x018 	0x0D 	WORD 	Physical sectors per track
# 0x01A 	0x0F 	WORD 	Number of heads
# 0x01C 	0x11 	DWORD 	Hidden sectors
# 0x020 	0x15 	DWORD 	Large total logical sectors

# 0x024 	0x19 	BYTE 	Physical drive number
# 0x025 	0x1A 	BYTE 	Flags etc.
# 0x026 	0x1B 	BYTE 	Extended boot signature (0x29 aka "4.1")
# 0x027 	0x1C 	DWORD 	Volume serial number
# 0x02B 	0x20 	11 BYTEs 	Volume label
# 0x036 	0x2B 	8 BYTEs 	File-system type

FAT_BPB_SEC_OFFS = 0x0b
FAT_PBP_FORMAT = "<HBHBHHBHHHIIBBBI11s8s"



def die(text):
    print(f"{progname}:", text, file=sys.stderr)
    sys.exit(1)

imgfile=""
def checkparams(argv):
    if len(argv) != 5:
        die(f"""{argv[0]} parameters:
        1. image file
        2. file in the image file
        3. filesystem type, FAT/Ext2
        4. filesystem offset in sectors""")

    global progname
    global imgfile
    global fname
    global fstype
    global offs

    progname = argv[0]
    imgfile = argv[1]
    fname = argv[2]
    fstype = argv[3]
    offs = argv[4]

    ## tests, eg. fstype in FAT, Ext2

    try:
        offs = int(offs)
    except ValueError:
        die(f"bad offset value: \"{offs}\"")

def main(argv):
    checkparams(argv)


def read(file, pos, len):
    with open(file, "rb") as f:
        f.seek(pos)
        data = f.read(len)
        return data

main(sys.argv)


print(imgfile, 512, offs, FAT_BPB_SEC_OFFS)  ###
packed_data = read(imgfile, offs * 512 + FAT_BPB_SEC_OFFS,
                   struct.calcsize(FAT_PBP_FORMAT))
print("packed_data: ", packed_data)  ###
struct.unpack(FAT_PBP_FORMAT, packed_data)  ###
(fat_bytes_per_sector, fat_sectors_per_cluster, fat_reserved_sectors,
 fat_number_of_fats, fat_root_entries, fat_total_sectors,
 fat_media_descriptor, fat_sectors_per_fat, fat_sectors_per_track,
 fat_number_of_heads, fat_hidden_sectors, fat_large_total_sectors,
 fat_physical_drive_number, fat_flags, fat_extended_boot_signature,
 fat_volume_serial_number, fat_volume_label, fat_file_system_type) = \
     struct.unpack(FAT_PBP_FORMAT, packed_data)

print(f"Bytes per logical sector    : {fat_bytes_per_sector}")
print(f"Logical sectors per cluster : {fat_sectors_per_cluster}")
print(f"Reserved logical sectors    : {fat_reserved_sectors}")
print(f"Number of FATs              : {fat_number_of_fats}")
print(f"Root directory entries      : {fat_root_entries}")
print(f"Total logical sectors       : {fat_total_sectors}")
print(f"Media descriptor            : 0x{fat_media_descriptor:x}")
print(f"Logical sectors per FAT     : {fat_sectors_per_fat}")

print(f"Physical sectors per track  : {fat_sectors_per_track}")
print(f"Number of heads             : {fat_number_of_heads}")
print(f"Hidden sectors              : {fat_hidden_sectors}")
print(f"Large total logical sectors : {fat_large_total_sectors}")

print(f"Physical drive number       : 0x{fat_physical_drive_number:2x}")
print(f"Flags etc.                  : 0x{fat_flags}")
print(f"Extended boot signature     : 0x{fat_extended_boot_signature:2x}")
print(f"Volume serial number        : 0x{fat_volume_serial_number:8x}")
print(f"Volume label                : {fat_volume_label}")
print(f"File-system type            : {fat_file_system_type}")

################################################################
#print(f"args.imgfile: {repr(args.imgfile)}")
#import os
#print(os.path.exists(args.imgfile))
################################################################

#print(args.imgfile)  ###
#with open(args.imgfile, mode='rb') as file:
#    content=file.read
