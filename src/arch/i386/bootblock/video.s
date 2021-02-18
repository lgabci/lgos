.arch i8086,nojumps
.code16

.if 0
.doxygen-begin
/**
 * @file video.s
 * @brief i386 video functions
 *
 * INT10h video BIOS functions
 */
.doxygen-end
.endif

.if 0
.doxygen-begin
/**
 * @def INT_VIDEO
 * @brief BIOS video interrupt
 */
/**
 * @def VID_TTY_OUT
 * @brief video teletype output
 */
/**
 * @def VID_GET_MODE
 * @brief get video mode and and active display page
 */
.doxygen-end
.endif

.set INT_VIDEO,      0x10
.set VID_TTY_OUT,    0x0e
.set VID_GET_MODE,   0x0f

.section .text  # ---------------------------------------------------------

.if 0
.doxygen-begin
/**
 * @brief initialize video
 *
 * Output:
 * - @ref page = active video page
 *
 * Modified registers:
 * - AX, BH
 */
void initvideo(void);
.doxygen-end
.endif

.globl initvideo
initvideo:
        movb    $VID_GET_MODE, %ah
        int     $INT_VIDEO
        movb    %bh, page
        ret

.if 0
.doxygen-begin
/**
 * @brief print a character
 *
 * print a character to the display in teletype mode, moves the cursor and
 * scrolls the screen if necessary
 *
 * BIOS bug: BH must be equal current active page
 *
 * @param[in] c AL = character to print
 *
 * Modified registers:
 * - AH, BX, BP (BIOS bug), flags
 */
void printchr(uint8_t c);
.doxygen-end
.endif

.globl printchr
printchr:
        movb    $VID_TTY_OUT, %ah
        movb    page, %bh
        int     $INT_VIDEO
        ret

.if 0
.doxygen-begin
/**
 * @brief print string
 *
 * print a zero terminated string to the display in teletype mode, moves
 * the cursor and scrolls the screen if necessary
 *
 * @param[in] c SI = pointer to zero terminated string
 *
 * Modified registers:
 * - AX, BX, SI, BP (BIOS bug), flags
 */
void printstr(uint8_t *c) {
.doxygen-end
.endif

.globl printstr
printstr:
1:      cld
        lodsb
        testb   %al, %al
        jz      2f
        call    printchr
        jmp     1b
2:      ret
.if 0
.doxygen-begin
}
.doxygen-end
.endif

.section .data  # ---------------------------------------------------------

.if 0
.doxygen-begin
/**
 * @var rows
 * @brief number of display rows@n
 * fixed value
 */
.doxygen-end
.endif
rows:   .byte 25

.section .bss  # ----------------------------------------------------------

.if 0
.doxygen-begin
/**
 * @var page
 * @brief number of active display page,
 * initialized by @ref initvideo
 */
.doxygen-end
.endif

.lcomm page, 1
