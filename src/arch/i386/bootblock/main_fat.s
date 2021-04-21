.arch i8086
.code16

/**
 * @file main_fat.s
 * @brief i386 bootblock, FAT
 *
 * Steps:
 * -# read sector at @ref addsec
 * -# read sectors 
 * -# start boot loader
 *
 * .jtext section for the first jump instruction
 *
 * Boot sector layout
 * | Address | Code | Length | Description            |
 * | ------- | :--: | -----: | ---------------------- |
 * |  0x0000 |  *   | 3      | BPB - Jump to code     |
 * |  0x0003 |      | 33     | BPB                    |
 * |  0x0024 |      | 54     | Extended BPB           |
 * |  0x005a |  *   | 420    | Boot code              |
 * |  0x00fe |      | 2      | Boot signature, 0xaa55 |
 *
 */

.section .jtext, "ax", @progbits  # ---------------------------------------
        jmp     start

.section .text  # ---------------------------------------------------------

/**
 * @brief i386 FAT boot sector main function
 *
 * i386 main
 *
 # void main(void) {
 */
.globl main
main:
        pushw   %dx
        call    initvideo

        movw    $fatstr, %si
        call    printstr


1:      cli
        hlt
        jmp     1b

/** } */

.section .data  # ---------------------------------------------------------

/** @brief physycal sector number of sector addresses, set by install script */
addsec: .long 0x0

fatstr: .string "LGOS FAT\r\n"    /**< @brief i386 welcome text */
