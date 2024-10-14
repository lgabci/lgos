/* LGOS i386 MBR asm file */
.code16
.arch i8086,nojumps

.set PARTTAB_START, 0x1be       // partition table start at this position
.set PARTENTRY_CNT, 4           // number of partition entries
.set PARENTRY_SIZE, 0x10        // partition entry size in bytes

.set PARENTRY_STAT, 0x00        // partition entry status byte
.set PARENTRY_START, 0x08       // partition entry LBA of 1st abs sector

.set BIOS_SEG, 0x07C0           // segment where MBR starts (0x0000:0x7C00)

.set BOOTSGN, 0xaa55            // boot signature

.section .text

.global main
main:
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
        jne     6f
        jmp     4f

3:                              // load loader


4:
        testw   %ax, %ax        // LBA start filled?
        jnz     5f
        testw   %dx, %dx
        jnz     5f
        jmp     6f

5:      movw    $BIOS_SEG, %bx  // chainload bootsector
        movw    %bx, %es
        xorw    %bx, %bx
        callw   read_sector

        cmpw    $BOOTSGN, %es:0x1fe
        jne     7f

        popw    %si             // values pass to VBR
        movw    %si, %bp
        popw    %es
        popw    %di
        popw    %dx

        xorw    %ax, %ax
        cli
        movw    %ax, %ss
        movw    $BIOS_SEG << 4, %sp
        sti

        ljmpw   $0, $BIOS_SEG << 4

6:      movw    $invptb, %si    // on error, invalid partition table
        jmp     halt

7:      movw    $invbs, %si     // on error, invalid boot sector
        jmp     halt

.section .data

ldrlba: .long 0                 // starting LBA of loader
ldrlen: .word 0                 // length of loader in 512 byte sectors

.global msgstr
msgstr: .string "LGOS MBR\r\n"  // message
invptb: .string "Invalid part table."
invbs:  .string "Invalid boot sector."
