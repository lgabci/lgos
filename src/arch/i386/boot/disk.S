/* LGOS boot loader disk asm file */
.code16
.arch i8086,nojumps

/**
* \file disk.S
* LGOS x86 boot disk asm
*/

#define INTDISK         0x13
#define GETSTAT         0x01
#define GETPRM          0x08

.section .text

/** \brief initialize disk system
*
* query CHS geometry by <tt>INT 13, 8</tt> \n
* sets words \c ncyls, \c nheads, \c nsecs
*
* \param DL BIOS disk ID
*
* \par Modified registers
* \c AX, \c BL, \c CL, \c DX, \c DI, \c flags, \c memory
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

.globl readsec
readsec:

/** \brief disk error
*
* prints an error message and halts computer with \ref die
*
* \param str error message
*
* \par Modified registers
* \modregs_indirect{AX, BH, SI, flags, memory}
*
#void diskerr(char* str) { }
*/
diskerr:
        movw    $dskerr, %si
        jmp     die

.section .data
dskerr: .asciz "Disk error.\r\n"

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
