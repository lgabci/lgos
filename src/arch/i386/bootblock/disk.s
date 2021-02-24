.arch i8086,nojumps
.code16

/**
 * @file disk.s
 * @brief i386 bootblock, disk I/O
 *
 * Steps:
*/

/** @brief BIOS disk interrupt */
.set INT_DISK ,      0x13

/** @brief reset disks */
.set DISK_RESET,     0x00

/** @brief read sectors */
.set DISK_READ,      0x02


.section .text  # ---------------------------------------------------------

/**
 * @brief reset disks
 *
 * @param disk @c DL = BIOS drive number
 *
 * static void diskreset(uint8_t disk) {
 */
diskreset:
        movb    $DISK_RESET, %ah
        jc      1f
        movw    $iostr, %si
        jmp     fatal
1:      ret

/** } */

/**
 * @brief read sector
 *
 * @param lba @c DX:AX = LBA sector number
 *
 * void diskread(uint32_t lba) {
 */

.globl diskread
diskread:
        movb    $DISK_RESET, %ah
        jc      1f
        movw    $iostr, %si
        jmp     fatal
1:      ret

.section .data  # ---------------------------------------------------------

/** @brief I/O error text */
iostr:  .string "I/O error\r\n"
