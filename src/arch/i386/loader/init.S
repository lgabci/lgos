/* LGOS i386 loader init asm file */
.code16gcc
.arch i8086,nojumps

.set STACK_SIZE, 0x200          // stack size in bytes

.set FLAGS_XOR, 0xf000          // test 386, mask flags
.set FLAGS_TST, 0x7000

.set VID_INT, 0x10              // video interrupt
.set VID_GETMODE, 0x0f          // get video mode and active page
.set VID_TTY, 0x0e              // teletype output

.section .itext, "ax", @progbits  // init .text section

.global start
start:
        cli                     // set stack and segment registers
        cld                     // ABI
        movw    %cs, %ax
        movw    %ax, %ss
        movw    $stkend, %sp
        sti
        movw    %ax, %ds
        movw    %ax, %es

        movw    $BSS_START, %di // zero fill bss
        movw    $BSS_SIZE, %cx
        xorw    %ax, %ax
rep     stosb

        pushfw                  // test 80386 CPU
        popw    %ax             // allows setting of Flags bits 12-14
        movw    %ax, %dx        // dont allows setting of Flags bit 15
        xorw    $FLAGS_XOR, %ax
        pushw   %ax
        popfw
        pushfw
        popw    %ax
        xorw    %dx, %ax
        cmpw    $FLAGS_TST, %ax
        jne     1f

        jmp     main

1:      xorb    %bh, %bh        // BIOS bug
        movb    $VID_GETMODE, %ah
        pushw   %bp             // BIOS bug
        int     $VID_INT        // get active video page into BH
        popw    %bp

        movw    $i386e, %si     // video TTY output
        movb    $VID_TTY, %ah

2:      lodsb                   // print error message
        testb   %al, %al
        jz      3f
        int     $VID_INT
        jmp     2b

3:      hlt
        jmp 3b

.section .data
i386e:  .string "LGOS loader requires minimum 80386 CPU."

.section .bss

        .balign 4               // stack
        .space STACK_SIZE
stkend:                         // top of stack
