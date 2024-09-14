/* LGOS i386 boot init asm file */
.code16gcc
//.arch i8086,nojumps

.section .text

.global main
main:
//////////////////////////////////////////////////////////////////////////////
//        movw    $0x0000, %dx
//        movw    $0x0008, %ax
//        movw    $0x400, %bx
//        call    read_sector
        movb    beh, %al
        cli
1:      hlt
        jmp     1b
//////////////////////////////////////////////////////////////////////////////


.section .data

beh:    .byte 0                 // behavior: 0 = original MBR, else loader

.global msgstr
msgstr: .string "LGOS MBR\r\n"  // message
