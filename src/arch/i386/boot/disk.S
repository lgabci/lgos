/** @file disk.S
*   @details LGOS loader disk.S file
*/

.code16
.arch i8086,nojumps

.set DISK_INT, 0x13             /**< @brief BIOS disk interrupt */
.set DISK_RESET, 0x00           /**< @brief reset disk system */
.set DISK_GETST, 0x01           /**< @brief get status of last operation */
.set DISK_READSEC, 0x02         /**< @brief read sectors */
.set DISK_GETPRM, 0x08          /**< @brief get drive parameters */

.set DISK_FDDRETRY, 0x05        /**< @brief retry FDD reads this many times */

.section .text

/** @brief initialize disk
*   @details mcyl, mhead, msec variables are filled when using HDD
*
*   @param [in] DL BIOS drive number
*   @details <b>modified registers</b>: AX, BL, CX, DX, DI, flags;
*            SI, BP: BIOS bug
#void init_disk(drive DL) {
#}
*/
.global init_disk
init_disk:
        movb    %dl, drive

        testb   $0x80, %dl      /* test if it is a floppy */
        jz      1f

        movb    $DISK_GETPRM, %ah
        pushw   %es
        pushw   %ds             /* BIOS bug */
        int     $DISK_INT
        popw    %ds
        popw    %es

        pushfw
        movb    $DISK_GETST, %ah  /* BIOS bug */
        movb    drive, %dl
        int     $DISK_INT
        popfw

        jc      9f              /* test error */

        movb    %cl, %al        /* max sector number */
        andb    $0x3f, %al
        cbtw
        movw    %ax, msec

        xorw    %ax, %ax        /* max head number, it can be 256 */
        movb    %dh, %al
        incw    %ax
        movw    %ax, mhead

        movw    %cx, %ax        /* max cylinder number */
        xchgb   %ah, %al
        movb    $6, %cl
        shrb    %cl, %ah
        incw    %ax
        movw    %ax, mcyl

        retw

1:      movw    msec, %cx       /* test if CHS is filled */
        jcxz    9f              /* cyl and head can be 0, but sec can not */
        retw

9:      movw    $dskerr, %si    /* on error */
        jmp     halt

/** @brief read LBA sector into memory
*
*   @param [in] DX_AX LBA of sector to read
*   @param [in] ES_BX pointer to data buffer
*   @details <b>modified registers</b>: AX, CX, DX, SI, DI, flags
#void read_sector(lba DX_AX,
#                 buf ES_BX) {
#}
*/
.global read_sector
read_sector:
        /* LBA to CHS:
                cyl  = lba / msec / mhead
                head = lba / msec mod mhead
                ssec = lba mod msec + 1
        */

        pushw   %ax             /* save LBA low word */
        xorw    %ax, %ax
        xchgw   %ax, %dx        /* high word div */
        divw    msec
        movw    %ax, %si        /* save result high word */
        popw    %ax
        divw    msec

        movw    %dx, %cx        /* sector number = remainder + 1 */
        incw    %cx

        movw    %si, %dx        /* DX:AX = LBA / nsec */
        cmpw    mhead, %dx      /* too big LBA? */
        jae     3f
        divw    mhead
        movb    %dl, %dh        /* head */

        cmpw    mcyl, %ax
        jae     3f
        pushw   %cx
        movb    $6, %cl
        shlb    %cl, %ah
        xchgb   %al, %ah        /* cylinder */
        popw    %cx
        orw     %ax, %cx

        movb    drive, %dl      /* drive */
        movw    $0x01, %di      /* retry count, HDD = 1, FDD = DISK_FDDRETRY */
        testb   $0x80, %dl
        jnz     1f
        movw    $DISK_FDDRETRY + 1, %di
1:
        movw    $DISK_READSEC << 8 | 0x01, %ax

        pushw   %dx             /* BIOS bug */
        stc                     /* BIOS bug */
        int     $DISK_INT
        sti                     /* BIOS bug */
        pop     %dx             /* BIOS bug */

        jc      2f
        retw
2:
        decw    %di             /* retry count -- */
        jz      3f

        movb    $DISK_RESET, %ah  /* disk reset before read retry */
        int     $DISK_INT
        jc      3f
        jmp     1b

3:      movw    $rderr, %si
        jmp     halt


.section .data

/** @brief maximum cylinder number
*   @details must be filled for FDDs and empty for HDDs@n
*            starts from 0
*/
mcyl:   .word 0x00

/** @brief maximum head number
*   @details must be filled for FDDs and empty for HDDs@n
*            starts from 0
*/
mhead:  .word 0x00

/** @brief maximum sector number
*   @details must be filled for FDDs and empty for HDDs@n
*            starts from 1
*/
msec:   .word 0x00

dskerr: .string "Disk error."           /**< @brief disk error message */
rderr:  .string "Read error."           /**< @brief read error message */

.section .bss

drive:  .byte 0                         /**< @brief BIOS drive number */
