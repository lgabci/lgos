/* LGOS i386 boot init asm file */
.code16
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

        pushw   %dx             // save values need to pass to VBR
        pushw   %di
        pushw   %es

        pushw   %dx             // save BIOS boot drive number

        movw    %ax, %ds        // copy code to 0x0600:0x0000
        movw    %ax, %es
        movw    $(BIOS_SEG - COPY_SEG) << 4, %si
        xorw    %di, %di
        movw    $BIN_SIZE >> 1, %cx
rep     movsw

        ljmpw   $COPY_SEG, $1f  // jump to new segment

.section .text
1:
        callw   init_video
        movw    $msgstr, %si
        callw   write_str

        popw    %dx             // restore BIOS drive number
        callw   init_disk

        jmp     main            // start of program

.section .data

.section .bss

        .balign 2               // stack
        .space STACK_SIZE
stkend:                         // top of stack
