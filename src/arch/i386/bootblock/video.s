.arch i8086,nojumps
.code16

.include "video_inc.s"

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
 * @def VID_GET_MODE
 * @brief get video mode and and active display page
 */
.doxygen-end
.endif

.set INT_VIDEO,      0x10
.set VID_GET_MODE,   0x0f

.section .text  # ---------------------------------------------------------

.if 0
.doxygen-begin
/**
 * @brief Initialize video
 *
 * Output:
 * - @ref cols = number of display columns (40 or 80)
 * - @ref page = active video page
 * - @ref rows = 25
 * - @ref color = @ref COLOR_LGRAY
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
        movb    %ah, cols
        movb    %bh, page
        ret

.section .data  # ---------------------------------------------------------

.if 0
.doxygen-begin
/**
 * @var rows
 * @brief number of display rows@n
 * fixed value
 */
/**
 * @var color
 * @brief dispay color@n
 * initial value = @ref COLOR_LGRAY@n
 * bit 7 = 0: don't blink, 1: blink@n
 * bit 4-6 = background color@n
 * bit 0-3 = foreground color
 */
.doxygen-end
.endif
rows: .byte 25
color: .byte 0x07

.section .bss  # ----------------------------------------------------------

.if 0
.doxygen-begin
/**
 * @var cols
 * @brief number of display columns,
 * initialized by @ref initvideo
 */
/**
 * @var page
 * @brief number of active display page,
 * initialized by @ref initvideo
 */
.doxygen-end
.endif

.lcomm cols, 1
.lcomm page, 1
