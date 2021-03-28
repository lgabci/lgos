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
.set DISK_GETPARAM,  0x08        /**< @brief get drive parameters */


.section .text  # ---------------------------------------------------------

/**
 * @brief reset disks system
 *
 * BIOS input
 * - AH = @ref DISK_RESET
 * - DL drive
 *
 * BIOS output
 * - CF = 0 if successful, 1 on error
 * - AH = status
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

/** @brief get drive parameters
 *
 * BIOS input
 * - AH = @ref DISK_GETPARAM
 * - DL drive
 *
 *
 * BIOS output
 * - CF = 0 if successful, 1 on error
 * - AH = status
 *
 # void initdisk(uint8_t DL -- [in] BIOS drive number
 #      ) {
 */
.globl initdisk
initdisk:
        movb    %dl, drive
        ret

/**
 * @brief read sectors into memory
 *
 * BIOS input
 * - AH = @ref DISK_READ
 * - AL = number of sectors to read
 * - CH = low 8 bits of cylinder number
 * - CL = bits 0-5: sector number, bits 6-7: high 2 bits of cylinder number
 * - DH = head number
 * - DL = drive number
 * - ES:BX = data buffer to read
 *
 * BIOS output
 * - CF = 0 if successful, 1 on error
 * - AH = status
 * - AL = number of sectors transferred, not all BIOSes when CF is not set
 *
 * notes
 * - on floppies retry reads at least 3 times
 * - make the buffer word aligned
 * - BIOS bug destroys DX
 * - BIOS bug improper set the CF: set CF before call INT
 *
 # void diskread(uint32_t DX_AX, -- [in] LBA sector number
 #               char *   ES_BX  -- [in] data buffer
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

.section .bss  # ----------------------------------------------------------

.lcomm drive, 1                       /**< @brief BIOS drive number */
