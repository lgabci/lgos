.arch i8086,nojumps
.code16

.if 0
.doxygen-begin
/**
 * @file common.s
 * @brief common functions
 *
 * boot bootblock functions, program execution starts here on @ref start
 */
.doxygen-end
.endif

.if 0
.doxygen-begin
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
.doxygen-end
.endif

.set BIOSSEG, 0x07C0
.set RELOCSEG, 0x0600
.set STACKSIZE, 0x100

.extern _BIN_START
.extern _BIN_SIZE

.section .text  # ---------------------------------------------------------

.if 0
.doxygen-begin
/**
 * @brief code starts to run here
 *
 * it will jump  to @c main
 *
 * - set segment registers: @c DS, @c ES, @c SS
 * - set up stack: @c SP
 * - set up <tt>CS:IP</tt>, far jump to @c 0x7C00:@ref main
 */
void start(void);
.doxygen-end
.endif

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

.if 0
.doxygen-begin
/**
 * @brief print error message and halt
 *
 * @param c pointer to zero terminated string to print
 *
 * Modified registers:
 * - AX, BX, SI, BP (BIOS bug), flags
 */
void fatal(char *c) {
.doxygen-end
.endif

.globl fatal
fatal:  call    printstr
1:      cli
        hlt
        jmp     1b
.if 0
.doxygen-begin
}
.doxygen-end
.endif

.section .bss  # ----------------------------------------------------------

.if 0
.doxygen-begin
/**
 * @brief stack, @ref STACKSIZE length in bytes
 */
.doxygen-end
.endif
.lcomm stack, STACKSIZE
