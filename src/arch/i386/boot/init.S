/* LGOS i386 boot init asm file */

.globl _start
_start:
### #####################################
        nop
        mov     $0x1234, %ax
        cli
1:      hlt
        jmp     1b
### #####################################
