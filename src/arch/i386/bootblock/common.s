.arch i8086
.code16

/**
 * @file common.s
 * @brief i386 common functions
 *
 * boot bootblock functions, program execution starts here on @ref start
 *
 * .itext section for the initialisation code, at the beginning of .text
 */

.set BIOSSEG, 0x07C0   /**< @brief BIOS loads MBR to <tt>0x0000:0x7C00</tt> */
.set RELOCSEG, 0x0600  /**< @brief relocate  MBR to <tt>0x0600:0000</tt> */
.set STACKSIZE, 0x100  /**< @brief size of stack in bytes */

.extern _BIN_START
.extern _BIN_SIZE

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

.section .text  # ---------------------------------------------------------

/**
 * @brief print error message and halt
 *
 * Modified registers:
 * - AX, BX, SI, BP (BIOS bug), flags
 *
 # void fatal(char *SI -- [in]  pointer to  string to print
 #      ) {
 */

.globl fatal
fatal:  call    printstr
1:      cli
        hlt
        jmp     1b

/** } */

.section .bss  # ----------------------------------------------------------

.lcomm stack, STACKSIZE  /**< @brief stack, @ref STACKSIZE length in bytes */
