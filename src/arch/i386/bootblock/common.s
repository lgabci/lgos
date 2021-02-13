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

/**
 * @brief BIOS loads MBR to <tt>0x0000:0x7C00</tt>
 */
.set BIOSSEG, 0x07C0

/**
 * @brief relocate  MBR to <tt>0x0600:0000</tt>
 */
.set RELOCSEG, 0x0600

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
 * - far jump to <tt>0x7C00:initstartret</tt>, set up <tt>CS:IP</tt>
 */
void start(void);
.doxygen-end
.endif

.globl start
start:
        cli
        movw    $RELOCSEG, %ax
        movw    %ax, %es
        movw    %ax, %ss
        movw    $BIOSSEG, %ax
        movw    %ax, %ds


        sti
        jmp     main
