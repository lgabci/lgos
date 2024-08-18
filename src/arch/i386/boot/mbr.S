/* LGOS i386 boot init asm file */
.code16gcc
.arch i8086,nojumps

.section .text


.section .data

beh:    .byte 0                 // behavior: 0 = original MBR, else loader

.global msgstr
msgstr: .string "LGOS MBR\r\n"  // message
