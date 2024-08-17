/* LGOS i386 boot init asm file */
.code16gcc
.arch i8086,nojumps

.set BIN_SIZE, 0x200            // size of .text and .data

.set BIOS_SEG, 0x07C0           // segment, where MBR starts (0x0000:0x7C00)
.set COPY_SEG, 0x0600           // to copy running MBR (0x0600:0x0000)

.set STACK_SIZE, 0x100          // stack size in bytes


.section .text

.globl _start
_start:
        cli                     // set stack
        cld                     // ABI
        movw    $COPY_SEG, %ax
        movw    %ax, %ss
        movw    $stkend, %sp
        sti

        movw    %ax, %ds
        movw    %ax, %es
        movw    $(BIOS_SEG - COPY_SEG) << 4, %si
        xorw    %di, %di
        movw    $BIN_SIZE >> 1, %cx
rep     movsw

        ljmp    $COPY_SEG, $1f
1:

//////////////////////////////////////////////////////////////////////////////
        cli
1:      hlt
        jmp     1b
//////////////////////////////////////////////////////////////////////////////

.section .bss

        .balign 2               // stack
        .space STACK_SIZE
stkend:                         // top of stack
