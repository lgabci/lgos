.arch i8086,nojumps
.code16

/**
 * @file video.s
 * @brief i386 video functions
 *
 * INT10h video BIOS functions
 */

.set INT_VIDEO,      0x10 /**< @brief BIOS video interrupt */

.set VID_TTY_OUT,    0x0e  /**< @brief video teletype output */
.set VID_GET_MODE,   0x0f  /**< @brief get video mode and and active page */


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
 # void initvideo(void) {
 */

.globl initvideo
initvideo:
        movb    $VID_GET_MODE, %ah
        int     $INT_VIDEO
        movb    %bh, page
        ret

/**
 * @brief print a character
 *
 * print a character to the display in teletype mode, moves the cursor and
 * scrolls the screen if necessary
 *
 * BIOS bug: BH must be equal current active page
 *
 * Modified registers:
 * - AH, BX, BP (BIOS bug), flags
 *
 # void printchr(uint8_t AL /**< [in] character to print */
 #      ) {
 */

.globl printchr
printchr:
        movb    $VID_TTY_OUT, %ah
        movb    page, %bh
        int     $INT_VIDEO
        ret

/**
 * @brief print string
 *
 * print a zero terminated string to the display in teletype mode, moves
 * the cursor and scrolls the screen if necessary
 *
 * Modified registers:
 * - AX, BX, SI, BP (BIOS bug), flags
 *
 # void printstr(uint8_t *SI /**< [in] pointer to string */
 #      ) {
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

.section .data  # ---------------------------------------------------------

rows:   .byte 25   /**< @brief number of display rows@n */

.section .bss  # ----------------------------------------------------------

.lcomm page, 1  /**< @brief number of active display page, */
