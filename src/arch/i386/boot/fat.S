/* LGOS boot loader FAT asm file */
.code16
.arch i8086,nojumps

.globl main
main:

// ----------------------------------------------------------
1:      hlt
        jmp     1b
// ----------------------------------------------------------
