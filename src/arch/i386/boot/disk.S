/* LGOS boot loader disk asm file */
.code16
.arch i8086,nojumps

/**
* \file disk.S
* LGOS x86 boot disk asm
*/

#define INTDISK         0x13
#define GETSTAT         0x01
#define READSEC         0x02
#define GETPRM          0x08

.section .text

/** \brief initialize disk system
*
* \details query CHS geometry by <tt>INT 13, 8</tt> \n
* sets words \ref ncyls, \ref nheads, \ref nsecs
*
* \param[in] DL BIOS disk ID
*
* \par Modified registers
* \modregs{AX, BL, \a BH, CL, DX, \a SI, DI, flags, memory}
*
#void initdisk(byte DL) { }
*/
.globl initdisk
initdisk:
        movb    %dl, drive
        movb    $GETPRM, %ah
        pushw   %ds             // BIOS bug
        pushw   %es
        int     $INTDISK
        sti                     // BIOS bug
        popw    %es
        popw    %ds             // BIOS bug

        movb    drive, %dl      // BIOS bug
        movb    $GETSTAT, %ah
        int     $INTDISK
        jc      diskerr

        movb    %cl, %al
        andw    $0x3f, %ax
        movw    %ax, nsecs

        movw    %cx, %ax
        movb    $6, %cl
        shrb    %cl, %al
        xchgb   %ah, %al
        incw    %ax
        movw    %ax, ncyls

        xorw    %ax, %ax
        movb    %dl, %al
        incw    %ax
        movw    %ax, nheads

        ret

/** \brief read sectors
*
* \details reads the given \a lba sector from disk to \a addr memory address
*
* \param[in] AX LBA low 16 bits
* \param[in] DX LBA hight 16 bits
* \param[in] ES segment address of memory to read
*
* \par Modified registers
* \todo modified registers
*
#void readsec(lba_h DX, lba_l AX, seg ES) { }
*/
.globl readsec

        movw    $READSEC << 8 | 1, %ax
        nop  ///
readsec:

/** \brief disk error
*
* \details prints an error message and halts computer with \ref die
*
* \param[in] str pointer to error message
*
* \par Modified registers
* \modregs{\a AX, \a BH, \a SI, \a flags, \a memory}
*
#void diskerr(byte* str) { }
*/
diskerr:
        movw    $dskerr, %si
        jmp     die

.section .data
dskerr: .asciz "Disk error.\r\n"        /**< Disk error message text */

ncyls:  .word 0         /**< number of cylinders */
nheads: .word 0         /**< number of heads */
nsecs:  .word 0         /**< number of sectors */

.section .bss
drive:  .byte 0         /**< BIOS disk ID \n
        value | drive
        ----- | -----
        0x00 | floppy A:
        0x01 | floppy B:
        ... | ...
        0x80 | hard disk C:
        0x081 | hard disk D:
        ... | ... */
