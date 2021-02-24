.arch i8086,nojumps
.code16

/**
 * @file common.s
 * @brief common functions
 *
 * boot bootblock functions, program execution starts here on @ref start
 */

/**
 * @def BIOSSEG
 * @brief BIOS loads MBR to <tt>0x0000:0x7C00</tt>
 */
/**
 * @def RELOCSEG
 * @brief relocate  MBR to <tt>0x0600:0000</tt>
 */
/**
 * @def STACKSIZE
 * @brief size of stack in bytes
 */

.set BIOSSEG, 0x07C0
.set RELOCSEG, 0x0600
.set STACKSIZE, 0x100

.extern _BIN_START
.extern _BIN_SIZE

.section .text  # ---------------------------------------------------------

/**
 * @brief code starts to run here
 *
 * it will jump  to @c main
 *
 * - set segment registers: @c DS, @c ES, @c SS
 * - set up stack: @c SP
 * - set up <tt>CS:IP</tt>, far jump to @c 0x7C00:@ref main
 *
 * void start(void) {
 */

.globl start
start:
        cli
        movw    $RELOCSEG, %ax
        movw    %ax, %ss
        movw    $stack + STACKSIZE, %sp
        sti

        movw    %ax, %ds
        movw    %ax, %es
        movw    $(BIOSSEG - RELOCSEG) << 4, %si  # source
        xorw    %di, %di                         # destination
        movw    $_BIN_SIZE, %cx
        cld
rep     movsb
        ljmp    $RELOCSEG, $main

/** } */

/**
 * @brief print error message and halt
 *
 * @param c pointer to zero terminated string to print
 *
 * Modified registers:
 * - AX, BX, SI, BP (BIOS bug), flags
 *
 * void fatal(char *c) {
 */

.globl fatal
fatal:  call    printstr
1:      cli
        hlt
        jmp     1b

/** } */

.section .bss  # ----------------------------------------------------------

/** @brief stack, @ref STACKSIZE length in bytes */
.lcomm stack, STACKSIZE
