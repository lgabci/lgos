.arch i8086,jumps
.code16

.if 0
.doxygenr-begin
/**
 * @dir bootblock
 * @brief i386 bootblock
 *
 * bootblocks for:
 * - i386 MBR
 * - FAT boot sector
 * - Ext2 boot sector
 */
.doxygen-end
.endif

.if 0
.doxygen-begin
/**
 * @file main_mbr.s
 * @brief i386 bootblock, MBR
 *
 * Steps:
 * -# BIOS loads MBR to <tt>0x0000:0x7C000</tt>
 * -# relocate MBR to 0x0600:0x0000 (@ref start)
 * -# find active partition's boot sector
 * -# load boot sector to <tt>0x0000:0x7C000</tt> and start it
 *
 * Initial environment by BIOS:
 * - CS:IP = 0x0000:0x7C00
 * - DL = BIOS drive number
 * - DH bit 5 = 0: device supported by INT13h, only some BIOSes
 * - ES:DI = PnP installation check structutre, only PnP BIOSes
 *
 * Environment to boot loader by MBR:
 * - CS:IP = 0x0000:0x7C00
 * - DL = boot drive unit
 * - DH = original DH set by BIOS
 * - ES:DI = original ES:DI set by BIOS
 * - DS:SI = points to the 16-byte MBR partiton table entry of boot loader
 * - DS:BP = points to the 16-byte MBR partiton table entry of boot loader
 *
 * @anchor MBR
 * Structure of a standard MBR:
 * | Address | Code | Size | Description                          |
 * | ------- | :--: | ---: | ------------------------------------ |
 * | 0x0000  |  *   |  218 | Bootstrap code area part 0           |
 * | 0x00DA  |      |    2 | 0x0000, disk timestamp               |
 * | 0x00DC  |      |    1 | Original physical drive, 0x80 - 0xFF |
 * | 0x00DD  |      |    1 | Seconds, 0 - 59                      |
 * | 0x00DE  |      |    1 | Minutes, 0 - 59                      |
 * | 0x00DF  |      |    1 | Hours, 0 - 23                        |
 * | 0x00E0  |  *   |  216 | Bootstrap code area part 1           |
 * | 0x01B8  |      |    4 | 32-bit disk signature, optional      |
 * | 0x01BC  |      |    2 | 0x0000, 0x5A5A = copy protected      |
 * | 0x01BE  |      |   16 | @ref PartEntry "Partition entry" #1  |
 * | 0x01CE  |      |   16 | @ref PartEntry "Partition entry" #2  |
 * | 0x01DE  |      |   16 | @ref PartEntry "Partition entry" #3  |
 * | 0x01EE  |      |   16 | @ref PartEntry "Partition entry" #4  |
 * | 0x01FE  |      |    1 | 0x55, Boot Signature                 |
 * | 0x01FF  |      |    1 | 0xAA, Boot Signature                 |
 *
 * @anchor PartEntry
 * Structure of a partition entry
 * | Offset | Length | Description |
 * | ------ | -----: | ----------- |
 * | 0x00   | 1      | bit 7: boot flag, 1 = bootable |
 * | 0x01   | 1      | CHS head address of 1st absolute sector of partition |
 * | 0x02   | 1      | bit 6-7: cylinder high bits@n bit 0-5: sector address |
 * | 0x03   | 1      | CHS cylinder low 8 bits |
 * | 0x04   | 1      | Partition type |
 * | 0x05   | 1      | CHS head address of last absolute sector of partition |
 * | 0x06   | 1      | bit 6-7: cylinder high bits@n bit 0-5: sector address |
 * | 0x07   | 1      | CHS cylinder low 8 bits |
 * | 0x08   | 4      | LBA of first absolute sector in the partition |
 * | 0x0C   | 4      | Number of sectors in partition |
 */

/**
 * @def PTABLE_START
 * @brief partition table's address in MBR, first @ref PartEntry
 * "partition entry"
 */
/**
 * @def PENTRY_SIZE
 * @brief size of a partition @ref PartEntry "partition entry"
 */
/**
 * @def PENTRY_CNT
 * @brief number of @ref PartEntry "partition entries" in @ref MBR
 */
.doxygen-end
.endif
.set PTABLE_START, 0x1be
.set PENTRY_SIZE,  0x10
.set PENTRY_CNT,   0x04

.section .text  # ---------------------------------------------------------

.if 0
.doxygen-begin
/**
 * @brief i386 MBR main function
 *
 * i386 main
 */
void main() {
.doxygen-end
.endif

.globl main
main:
        call    initvideo

        movw    $mbrstr, %si
        call    printstr



        # find active partition
        xorw    %bp, %bp
        movw    $PTABLE_START, %si
        movw    $PENTRY_CNT, %cx

1:      movb    (%si), %al
        testb   $0x80, %al              # boot flag?
        jz      2f
        testw   %bp, %bp                # another one active partition?
        jz      3f
        movw    $invstr, %si
        jmp     fatal
3:      movw    %si, %bp                # BP -> active partition entry

2:      addw    $PENTRY_SIZE, %si
        loop    1b

        testw   %bp, %bp                # another one active partition?
        jnz     1f
        movw    $nastr, %si
        jmp     fatal
1:





1:      cli
        hlt
        jmp     1b
.if 0
.doxygen-begin
}
.doxygen-end
.endif

## ------------------------------------------------------------------------
.section .data

.if 0
.doxygen-begin
/**
 * @brief i386 MBR welcome text
 */
.doxygen-end
.endif

mbrstr: .string "LGOS MBR\r\n"

.if 0
.doxygen-begin
/**
 * @brief invalid MBR message
 */
.doxygen-end
.endif

invstr: .string "Invalid MBR"

.if 0
.doxygen-begin
/**
 * @brief no active partition message
 */
.doxygen-end
.endif

nastr:  .string "No active partition found"
