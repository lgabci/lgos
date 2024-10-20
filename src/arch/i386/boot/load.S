/* LGOS i386 load asm file */
.code16
.arch i8086,nojumps

.section .text

.global main
main:
        movw    ldrlba, %ax
        movw    ldrlba + 2, %dx
        movw    ldrlen, %cx
        cli                     //
        hlt                     //
        jmp     main            //

.section .data

.global msgstr
.ifdef FAT
msgstr: .string "LGOS FAT\r\n"  // message
.endif
.ifdef EXT2
msgstr: .string "LGOS Ext2\r\n"  // message
.endif

ldrlba: .quad 0                 // starting LBA sector of loader
ldrlen: .word 0                 // size of loader in 512 byte sectors
