.arch i8086
.code16

/**
 * @file main_loader.s
 * @brief common functions
 *
 * loader, program execution starts here on @ref start
 *
 * .itext section for the initialisation code, at the beginning of .text
 */
.section .itext, "ax", @progbits  # ---------------------------------------

/**
 * @brief code starts to run here
 *
 * it will jump to @ref main
 *
 * - set segment registers: @c DS, @c ES, @c SS
 * - set up stack: @c SP
 * - set up <tt>CS:IP</tt>, far jump to @c 0x7C00:@ref main
 * - don't touch DL (BIOS drive number)
 *
 # void start(void) {
 */

.globl start
start:
        cli

.rept 8192
        nop
.endr
1:
        hlt
        jmp     1b

/** } */
