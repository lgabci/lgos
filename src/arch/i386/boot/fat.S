/* LGOS i386 FAT asm file */
.code16
.arch i8086,nojumps

.section .text

.global main
main:
        nop                     //
        cli                     //
        hlt                     //
        jmp     main            //

.section .data

.global msgstr
msgstr: .string "LGOS boot\r\n"  // message
