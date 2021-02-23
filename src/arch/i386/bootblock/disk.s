.arch i8086,nojumps
.code16

.if 0
.doxygen-begin
/**
 * @file disk.s
 * @brief i386 bootblock, disk I/O
 *
 * Steps:
*/
.doxygen-end
.endif

.if 0
.doxygen-begin
/**
 * @def INT_DISK
 * @brief BIOS disk interrupt
 */
/**
 * @def DISK_RESET
 * @brief reset disks
 */
/**
 * @def DISK_READ
 * @brief read sectors
 */
.doxygen-end
.endif

.set INT_DISK ,      0x13
.set DISK_RESET,     0x00
.set DISK_READ,      0x02

.section .text  # ---------------------------------------------------------

.if 0
.doxygen-begin
/**
 * @brief reset disks
 *
 * @param disk @c DL = BIOS drive number
 */
void diskreset(uint8_t disk) {
.doxygen-end
.endif

.globl diskreset
diskreset:
        movb    $DISK_RESET, %ah
        jc      1f
        movw    $iostr, %si
        jmp     fatal
1:      ret

.if 0
.doxygen-begin
}
.doxygen-end
.endif

.if 0
.doxygen-begin
/**
 * @brief read sector
 *
 * @param lba @c DX:AX = LBA sector number
 */
void diskread(uint32_t lba) {
.doxygen-end
.endif

.globl diskread
diskread:
        movb    $DISK_RESET, %ah
        jc      1f
        movw    $iostr, %si
        jmp     fatal
1:      ret

.section .data  # ---------------------------------------------------------

.if 0
.doxygen-begin
/**
 * @brief I/O error text
 */
.doxygen-end
.endif

iostr:  .string "I/O error\r\n"
