/* LGOS boot loader init asm file */

.globl start
start:
        cli
        hlt
        jmp     start
