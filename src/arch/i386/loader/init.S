/* LGOS i386 loader init asm file */
.code16gcc
.arch i8086,nojumps


.global start
start:
        cli                     // set stack
        cld                     // ABI

movw $0xb800, %ax
movw %ax, %ds
movb 'A, %al
movb %al, 0
cli
1:
hlt
jmp 1b
