.arch i8086
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
 *
 * Modified registers:
 * - AX, BH
 */
void initvideo(void);
.doxygen-end
.endif

.globl initvideo
initvideo:


.section .data  # ---------------------------------------------------------

.if 0
.doxygen-begin
/**
 * @brief number of display rows,
 * fixed value: 25
 */
static unsigned char rows;
.doxygen-end
.endif
rows: .byte 25

.if 0
.doxygen-begin
/**
 * @brief number of display rows,
 * fixed value: 25
 */
static unsigned char color;
.doxygen-end
.endif
color: .byte 0x07


.section .bss  # ----------------------------------------------------------

.if 0
.doxygen-begin
/**
 * @brief number of display columns,
 * initialized by @ref initvideo
 */
static unsigned char cols;
.doxygen-end
.endif
.lcomm cols, 1

.if 0
.doxygen-begin
/**
 * @brief number of active display page,
 * initialized by @ref initvideo
 */
static unsigned char page;
.doxygen-end
.endif
.lcomm page, 1
