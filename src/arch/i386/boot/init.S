/* LGOS i386 boot init asm file */
.code16gcc
.arch i8086,nojumps

.set BIN_SIZE, 0x200            // size of .text and .data

.set BIOS_SEG, 0x07C0           // segment where MBR starts (0x0000:0x7C00)
.set COPY_SEG, 0x0600           // to copy running MBR (0x0600:0x0000)

.set STACK_SIZE, 0x100          // stack size in bytes

.section .itext, "ax", @progbits  // init .text section

.global start
start:
        cli                     // set stack
        cld                     // ABI
        movw    $COPY_SEG, %ax
        movw    %ax, %ss
        movw    $stkend, %sp
        sti

        movw    %dx, bdx        // save values nedd to pass to VBR
        movw    %es, bes
        movw    %di, bdi

        pushw   %dx             // save BIOS boot drive number

        movw    %ax, %ds        // copy code to 0x0600:0x0000
        movw    %ax, %es
        movw    $(BIOS_SEG - COPY_SEG) << 4, %si
        xorw    %di, %di
        movw    $BIN_SIZE >> 1, %cx
rep     movsw

        ljmp    $COPY_SEG, $1f  // jump to new segment

.section .text
1:
        call    init_video
        movw    $msgstr, %si
        call    write_str

        popw    %dx             // restore BIOS drive number
        call    init_disk

        jmp     main            // start of program

.section .data

.section .bss
.global bdx
bdx:    .word 0                 // BIOS DX value, pass to VBR
.global bes
bes:    .word 0                 // BIOS ES value, pass to VBR
.global bdi
bdi:    .word 0                 // BIOS DI value, pass to VBR

        .balign 2               // stack
        .space STACK_SIZE
stkend:                         // top of stack
