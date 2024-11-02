/* LGOS i386 loader init asm file */
.code16gcc
.arch i8086,nojumps

.set STACK_SIZE, 0x200          // stack size in bytes

.section .itext, "ax", @progbits  // init .text section

.global start
start:
        cli                     // set stack
        cld                     // ABI
        movw    %cs, %ax
        movw    %ax, %ss
        movw    $stkend, %sp
        sti

        movw    %ax, %ds
        movw    %ax, %es


        // test 80386 CPU


        call    main

        cli
1:      hlt
        jmp 1b

.section .bss

        .balign 4               // stack
        .space STACK_SIZE
stkend:                         // top of stack
