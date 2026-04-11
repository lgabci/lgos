/* LGOS boot loader init asm file */
.code16gcc

#define OLDSEG  0x7c0
#define NEWSEG  0x600

#define STACKSIZE       0x100

.section .text

.globl start
start:
        cli
        cld

        movw    $NEWSEG, %ax
        movw    %ax, %ds
        movw    %ax, %es
        movw    %ax, %ss

        xorw    %ax, %ax
        movw    $__bss_start, %di
        movw    $__bss_size, %cx
rep     stosb

        movw    $stackend, %sp
        sti

        movw    $__text_start + (OLDSEG - NEWSEG) << 4, %si
        xorw    %di, %di
        movw    $__text_and_data_size, %cx
rep     movsb

        ljmp    $NEWSEG, $1f
1:

        call    initvideo
        movw    $welstr, %si
        call    print

// ----------------------------------------------------------
1:      hlt
        jmp     1b
// ----------------------------------------------------------

.section .data
welstr: .asciz "MBR\n\r"

.section .bss

.align 2
stack:
.skip STACKSIZE
stackend:
