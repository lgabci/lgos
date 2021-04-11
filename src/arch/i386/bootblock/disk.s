.arch i8086
.code16

/**
 * @file disk.s
 * @brief i386 bootblock, disk I/O
 *
 * Steps:
*/

.set INT_DISK,       0x13        /**< @brief BIOS disk interrupt */
.set DISK_RESET,     0x00        /**< @brief reset disks */
.set DISK_GETSTATUS, 0x01        /**< @brief get status of last operation */
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
 * Modified registers:
 * - AX, DL, flags
 *
 # static void diskreset() {
 */
diskreset:
        movb    $DISK_RESET, %ah
        movb    drive, %dl
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
 * - BL = floppy drive type
 * - CH = low 8 bits of cylinder number
 * - CL = bits 0-5: maximum sector number,@n
 *   bits 6-7: high 2 bits of maximum cylinder number
 * - DH = maximum head number
 * - DL = number of drives
 * - ES:DI = drive parameter table, floppies only
 *
 * BIOS bugs
 * - DI, SI, BP, DS, ES registers destroyed
 * - call @ref DISK_GETSTATUS to reset bus
 * - leave interrupts diasbled, STI after interrupt
 *
 * Modified registers:
 * - AX, BL, CX, DX, DI, SI, BP, ES
 *
 # void initdisk(uint8_t DL -- [in] BIOS drive number
 #      ) {
 */
.globl initdisk
initdisk:
        movb    %dl, drive
        movb    $DISK_GETPARAM, %ah
        pushw   %ds
        pushw   %es
        int     $INT_DISK               # get drive parameters
        sti
        popw    %es
        popw    %ds
        jc      1f                      # on error

        movw    %cx, %ax                # CL: low 5 bits = sector number
        andw    $0x03f, %cx
        movw    %cx, secn

        xchgb   %ah, %al                # AX = CX: CH = low 8 bits of cyl
        movb    $6, %cl                 #          CL bits 6-7 = hight 2 bits
        shrb    %cl, %ah
        incw    %ax
        movw    %ax, cyln

        xorw    %ax, %ax                # DH = head number
        movb    %dh, %al
        incw    %ax
        movw    %ax, headn

        ret

1:      testb   %dl, %dl                 # floppy 0: on error assume 360KB
        jne     _ioerr
        ret

/**
 * @brief read sectors into memory
 *
 * @todo repeat floppy reads on error
 * @todo save registers between repeated reads
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
 * Modified registers:
 * - AX, BX, CX, DX, SI, flags
 *
 # void diskread(uint32_t DX_AX, -- [in] LBA sector number
 #               char *ES_BX  -- [in] data buffer
 #      ) {
 */

.globl diskread
diskread:
        xchgw   %ax, %cx                # save dividend low byte
        xorw    %ax, %ax
        xchgw   %dx, %ax
        movw    $secn, %si              # number of sectors, 6 bits
        divw    (%si)                   # div high byte

        xchgw   %ax, %cx                # rest dividend low byte, save hi byte
        divw    (%si)                   # div remainder + low byte

        incw    %dx                     # remainder, sector number, 6 bits
        xchgw   %dx, %cx                # DX:AX = LBA / secn, 18 bits

        movw    $headn, %si             # cyl number is 10 bits long
        cmpw    (%si), %dx              # DX < headn
        jae      _geoerr

        # DX:AX = LBA / sectors per track
        # CX = sector number (low 5 bits)

        divw    (%si)

        # AX = cylinder number, 10 bits (LBA / sectors per track / heads)
        # DX = head number

        cmpw    $cyln, %ax              # valid cylinder number?
        jae     _geoerr

        xchgb   %dh, %dl
        movb    drive, %dl              # DX = head number and drive

        movb    %al, %ch
        rorb    $1, %ah
        rorb    $1, %ah
        orb     %ah, %cl

        movw    $DISK_READ << 8 | 1, %ax
        pushw   %dx
        stc
        int     $INT_DISK
        sti
        popw    %dx

        jc      _ioerr
        ret

/**
 * @brief print I/O error message, halt machine
 *
 * make I/O error calls shorten
 *
 # static void _ioerr(void) {
 #  fatal();
 */
_ioerr:
        movw    $iostr, %si
        jmp     fatal
/** } */

/**
 * @brief print Geom error message, halt machine
 *
 * make Geom error calls shorten
 *
 # static void _geoerr(void) {
 #  fatal();
 */
_geoerr:
        movw    $geostr, %si
        jmp     fatal
/** } */

.section .data  # ---------------------------------------------------------

iostr:  .string "I/O error\r\n"         /**< @brief I/O error text */
geostr: .string "Geom error\r\n"        /**< @brief Geom error text */

cyln:   .word 0x28                      /**< @brief Maximum cylinder number */
headn:  .word 0x02                      /**< @brief Maximum head number */
secn:   .word 0x09                      /**< @brief Maximum sector number */

.section .bss  # ----------------------------------------------------------

.lcomm drive, 1                         /**< @brief BIOS drive number */
