/* LGOS boot loader Ext2 asm file */
.code16
.arch i8086,nojumps

.section .text

.globl main
main:

// ----------------------------------------------------------
1:      hlt
        jmp     1b
// ----------------------------------------------------------
