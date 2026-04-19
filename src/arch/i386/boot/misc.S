/* LGOS boot loader misc asm file */
.code16
.arch i8086,nojumps

.section .text

.globl die
die:    call    print
        cli
1:      hlt
        jmp     1b
