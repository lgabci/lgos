/* LGOS i386 load asm file */
.code16
.arch i8086,nojumps

.set LDRSEG, 0x07c0             // loader segment
.set SECSIZE, 0x200             // sector size

.section .text

.global main
main:
        movw    ldrlba, %ax     // load blootblock list to 0x0600:0x0400
        movw    ldrlba + 2, %dx

        movw    %ax, %bx        // is lba list address filled?
        orw     %dx, %bx
        jz      2f

        movw    $__end, %bx
        pushw   %bx             // using in loop
        call    read_sector

        movw    ldrlen, %cx     // read blocks to 0x07C0:0000
        jcxz    2f
        movw    $LDRSEG, %ax
        movw    %ax, %es
        xorw    %bx, %bx
        popw    %si

1:      lodsw                   // load next block LBA address
        xchgw   %dx, %ax
        lodsw
        xchgw   %dx, %ax

        pushw   %cx
        pushw   %si
        call    read_sector
        popw    %si
        popw    %cx

        addw    $SECSIZE, %bx
        loop    1b

        ljmpw   $LDRSEG, $0     // jmp to loader

2:      movw    $blkinv, %si
        jmp     halt

.section .data

.global msgstr
.ifdef FAT
msgstr: .string "LGOS FAT\r\n"  // message
.endif
.ifdef EXT2
msgstr: .string "LGOS Ext2\r\n"  // message
.endif

blkinv: .string "Invalid blocklist\r\n" // invalid blocklist

ldrlba: .int 0                  // starting LBA sector of loader
ldrlen: .word 0                 // size of loader in 512 byte sectors
