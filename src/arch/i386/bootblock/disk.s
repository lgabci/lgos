.arch i8086,nojumps
.code16

/**
 * @file disk.s
 * @brief i386 bootblock, disk I/O
 *
 * Steps:
*/

.set INT_DISK,       0x13        /**< @brief BIOS disk interrupt */
.set DISK_RESET,     0x00        /**< @brief reset disks */
.set DISK_READ,      0x02        /**< @brief read sectors */


.section .text  # ---------------------------------------------------------

/**
 * @brief reset disks
 *
 # static void diskreset(uint8_t DL -- [in] BIOS drive number
 #      ) {
 */
diskreset:
        movb    $DISK_RESET, %ah
        jc      1f
        movw    $iostr, %si
        jmp     fatal
1:      ret

/**
 * @brief read sector
 *
 # void diskread(uint32_t DX_AX -- [in] LBA sector number
 #      ) {
 */

.globl diskread
diskread:
        movb    $DISK_RESET, %ah
        jc      1f
        movw    $iostr, %si
        jmp     fatal
1:      ret

.section .data  # ---------------------------------------------------------

iostr:  .string "I/O error\r\n"       /**< @brief I/O error text */
