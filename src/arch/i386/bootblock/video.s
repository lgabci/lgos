.arch i8086,nojumps
.code16

/**
 * @file video.s
 * @brief i386 video functions
 *
 * INT10h video BIOS functions
 */

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

.set INT_VIDEO,      0x10
.set VID_TTY_OUT,    0x0e
.set VID_GET_MODE,   0x0f

.section .text  # ---------------------------------------------------------

/**
 * @brief initialize video
 *
 * Output:
 * - @ref page = active video page
 *
 * Modified registers:
 * - AX, BH
 *
 * void initvideo(void) {
 */

.globl initvideo
initvideo:
        movb    $VID_GET_MODE, %ah
        int     $INT_VIDEO
        movb    %bh, page
        ret

/** } */

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
 *
 * void printchr(uint8_t c) {
 */

.globl printchr
printchr:
        movb    $VID_TTY_OUT, %ah
        movb    page, %bh
        int     $INT_VIDEO
        ret

/** } */

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
 *
 * void printstr(uint8_t *c) {
 */

.globl printstr
printstr:
1:      cld
        lodsb
        testb   %al, %al
        jz      2f
        call    printchr
        jmp     1b
2:      ret

/** } */

.section .data  # ---------------------------------------------------------

/**
 * @var rows
 * @brief number of display rows@n
 * fixed value
 */
rows:   .byte 25

.section .bss  # ----------------------------------------------------------

/**
 * @var page
 * @brief number of active display page,
 * initialized by @ref initvideo
 */
.lcomm page, 1
