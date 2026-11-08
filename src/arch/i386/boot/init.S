/* LGOS boot loader init asm file */
.code16
.arch i8086,nojumps


#define MBR_TARGET      0
#define FAT_TARGET      1
#define EXT2_TARGET     2

#define OLDSEG  0x7c0
#define NEWSEG  0x600

#define STACKSIZE       0x100

#if BS_TARGET == FAT_TARGET     // FAT
.section .jstart, "ax", @progbits
.globl jstart
jstart:
        jmp     start

.section .text
#else                           // MBR, Ext2
.section .itext, "ax", @progbits
#endif

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

#if BS_TARGET != FAT_TARGET     // MBR, Ext2
.section .text
#endif
1:

        call    initvideo
        movw    $welstr, %si
        call    print

        call    initdisk        // with unmodified DX from BIOS

        jmp     main

.section .data
welstr:
#if BS_TARGET == MBR_TARGET
        .asciz "MBR\n\r"
#elif BS_TARGET == FAT_TARGET
        .asciz "FAT\n\r"
#elif BS_TARGET == EXT2_TARGET
        .asciz "Ext2\n\r"
#endif

.section .bss

.align 2
stack:
.skip STACKSIZE
stackend:
