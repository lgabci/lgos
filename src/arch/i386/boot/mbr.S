/* LGOS i386 boot init asm file */
.code16
.arch i8086,nojumps

.set PARTTAB_START, 0x1be       // partition table start at this position
.set PARTENTRY_CNT, 4           // number of partition entries
.set PARENTRY_SIZE, 0x10        // partition entry size in bytes

.set PARENTRY_STAT, 0x00        // partition entry status byte
.set PARENTRY_START, 0x08       // partition entry LBA of 1st abs sector

.set BIOS_SEG, 0x07C0           // segment where MBR starts (0x0000:0x7C00)

.section .text

.global main
main:
        cmpb    $0, beh         // behavior, 0 = load active boot block
        jne     load_ldr        //           else load loader

        movw    $PARTTAB_START, %si
        movw    $PARTENTRY_CNT, %cx
        xorw    %ax, %ax        // DX:AX = LBA of 1st sector of partition
        xorw    %dx, %dx
        xorw    %di, %di        // active partition counter


1:      testb   $0x80, PARENTRY_STAT(%si)
        jz      2f

        pushw   %si             // save to pass to VBR
        incw    %di
        movw    PARENTRY_START(%si), %ax
        movw    PARENTRY_START+2(%si), %dx

2:      addw    $PARENTRY_SIZE, %si
        loop    1b

        cmpw    $1, %di         // only 1 active partition
        ja      4f
        jb      4f

        testw   %ax, %ax        // LBA start filled
        jnz     3f
        testw   %dx, %dx
        jnz     3f
        jmp     4f

3:      movw    $BIOS_SEG, %bx  // chainload bootsector
        movw    %bx, %es
        xorw    %bx, %bx
        callw   read_sector

        popw    %si             // values pass to VBR
        movw    %si, %bp
        popw    %es
        popw    %di
        popw    %dx

        xorw    %ax, %ax
        cli
        movw    %ax, %ss
        movw    $BIOS_SEG << 4, %sp

        ljmpw   $0, $BIOS_SEG << 4

4:      movw    $invptb, %si    // on error
        jmp     halt

.section .data

beh:    .byte 0                 // behavior: 0 = original MBR, else loader

.global msgstr
msgstr: .string "LGOS MBR\r\n"  // message
invptb: .string "Invalid partition table."
