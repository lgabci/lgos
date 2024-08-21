/* LGOS i386 boot disk asm file */
.code16gcc
.arch i8086,nojumps

.set DISK_INT, 0x13             // video interrupt
.set DISK_RESET, 0x00           // reset disk system
.set DISK_GETST, 0x01           // get status of last operation
.set DISK_GETPRM, 0x08          // get drive parameters

.section .text

/* initialize disk
   input: DL = BIOS drive number
   output:
   modified: AX, BL, CX, DX, DI, flags; SI, BP: BIOS bug
*/
.global init_disk
init_disk:
        movb    %dl, drive

        testb   $0x80, %dl      // test if it is a floppy
        jz      1f

        movb    $DISK_GETPRM, %ah
        pushw   %es
        pushw   %ds             // BIOS bug
        int     $DISK_INT
        popw    %ds
        popw    %es

        movb    $DISK_GETST, %ah  // BIOS bug
        movb    drive, %dl
        int     $DISK_INT

test error

        movb    %cl, %al        // max sector number
        andb    $0x3f, %al
        movb    %al, msec

        xorw    %ax, %ax        // max head number, it can be 256
        movb    %dh, %al
        incw    %ax
        movw    %ax, mhead

        movw    %cx, %ax        // max cylinder number
        xchgb   %ah, %al
        movb    $6, %cl
        shrb    %cl, %ah
        incw    %ax
        movw    %ax, mcyl

        ret

1:
test if CHS is filled
        ret


/* reset disk system
   input: -
   output: reset disk
   modified: AH, DL, flags
*/
.global reset_disk
reset_disk:
        movb    $DISK_RESET, %ah
        movb    drive, %dl
        int     $DISK_INT
        ret

.section .data

mcyl:   .word 0x00              // disk geometry: must be filled for FDDs
mhead:  .word 0x00              //                must be empty for HDDs
msec:   .byte 0x00

.section .bss

drive:  .byte 0
