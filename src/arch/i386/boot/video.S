/* LGOS boot loader video asm file */
.code16gcc

#define INTVIDEO        0x10
#define TTYOUT          0x0e
#define GETCURVIDMODE   0x0f

.section .text

.globl initvideo
initvideo:
        movb    $GETCURVIDMODE, %ah
        int     $INTVIDEO
        movb    %bh, vpage
        ret

.globl print
print:
        movb    $TTYOUT, %ah
        movb    vpage, %bh

1:      lodsb
        test    %al, %al
        jz      2f
        int     $INTVIDEO
        jmp     1b
2:      ret

.section .bss
vpage:  .byte 0
