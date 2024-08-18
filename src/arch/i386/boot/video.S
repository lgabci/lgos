/* LGOS i386 boot video asm file */
.code16gcc
.arch i8086,nojumps

.set vid_int, 0x10              // video interrupt
.set vid_getmode, 0x0f          // get video mode and active page
.set vid_tty, 0x0e              // teletype output

.section .text

/* get current video page
   input: -
   output: vpg = current video page
   modified: AX, BH
*/
.global init_video
init_video:
        movb    $vid_getmode, %ah
        int     $vid_int
        movb    %bh, vpg
        ret

/* teletype output
   input: AL = character to write
   output: -
   modified: AX, BX, BP (BIOS bug)
*/
.global write_chr
write_chr:
        movb    $vid_tty, %ah
        movb    vpg, %bh
        int     $vid_int
        ret

/* print string
   input: SI = pointer to zero terminated string
   output: -
   modified: AX, BX, BP (BIOS bug)
*/
.global write_str
write_str:
        lodsb
        orb     %al, %al
        jnz     1f
        ret
1:      call    write_chr
        jmp     write_str

.section .data
vpg:    .byte   0x00
