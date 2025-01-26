/* LGOS i386 boot video asm file */

/** @file video.S
* LGOS loader video.S file
*/

.code16
.arch i8086,nojumps

.set VID_INT, 0x10              // video interrupt
.set VID_GETMODE, 0x0f          // get video mode and active page
.set VID_TTY, 0x0e              // teletype output

.section .text

/* initialize video: get current video page
   input: -
   output: vpg = current video page
   modified: AX, BH
*/
.global init_video
init_video:
        xorb    %bh, %bh        // BIOS bug
        movb    $VID_GETMODE, %ah
        int     $VID_INT
        movb    %bh, vpg
        retw

/* teletype output
   input: AL = character to write
   output: -
   modified: AX, BX, BP (BIOS bug)
*/
.global write_chr
write_chr:
        movb    $VID_TTY, %ah
        movb    vpg, %bh
        int     $VID_INT
        retw

/* print string
   input: SI = pointer to zero terminated string
   output: -
   modified: AX, BX, SI, BP (BIOS bug)
*/
.global write_str
write_str:
        lodsb
        orb     %al, %al
        jnz     1f
        retw
1:      callw   write_chr
        jmp     write_str

.section .data
vpg:    .byte   0x00
