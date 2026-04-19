/* LGOS boot loader disk asm file */
.code16
.arch i8086,nojumps

#define INTDISK         0x13
#define GETSTAT         0x01
#define GETPRM          0x08

.section .text

.globl initdisk
initdisk:
        movb    %dl, drive
        movb    $GETPRM, %ah
        pushw   %ds             /* BIOS bug */
        pushw   %es
        int     $INTDISK
        sti                     /* BIOS bug */
        popw    %es
        popw    %ds             /* BIOS bug */

        movb    drive, %dl      /* BIOS bug */
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

diskerr:
        movw    $dskerr, %si
        jmp     die

.section .data
dskerr: .asciz "Disk error.\r\n"

ncyls:  .word 0
nheads: .word 0
nsecs:  .word 0

.section .bss
drive:  .byte 0
