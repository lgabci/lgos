/* LGOS i386 loader init asm file */
.code16gcc
.arch i8086,nojumps


.global start
start:
        cli                     // set stack
        cld                     // ABI

movw $0xb800, %ax
pushw %ds
movw %ax, %ds
movb $'*', 0
movb $83, 1
popw %ds
pushw %ax
cli
1:
hlt
jmp 1b
