.arch i8086
.code16

.if 0
.doxygen-begin
/**
 * @file video_inc.s
 * @brief i386 video functions include file
 *
 * Text mode colors
 * | Symbol name    | Value |
 * | -------------- | ----: |
 * | COLOR_BLACK    | 0x00  |
 * | COLOR_BLUE     | 0x01  |
 * | COLOR_GREEN    | 0x02  |
 * | COLOR_CYAN     | 0x03  |
 * | COLOR_RED      | 0x04  |
 * | COLOR_MAGENTA  | 0x05  |
 * | COLOR_BROWN    | 0x06  |
 * | COLOR_LGRAY    | 0x07  |
 * | COLOR_DGRAY    | 0x08  |
 * | COLOR_LBLUE    | 0x09  |
 * | COLOR_LGREEN   | 0x0a  |
 * | COLOR_LCYAN    | 0x0b  |
 * | COLOR_LRED     | 0x0c  |
 * | COLOR_LMAGENTA | 0x0d  |
 * | COLOR_YELLOW   | 0x0e  |
 * | COLOR_WHITE    | 0x0f  |
 */
.doxygen-end
.endif

.set COLOR_BLACK, 0x00
.set COLOR_BLUE, 0x01
.set COLOR_GREEN, 0x02
.set COLOR_CYAN, 0x03
.set COLOR_RED, 0x04
.set COLOR_MAGENTA, 0x05
.set COLOR_BROWN, 0x06
.set COLOR_LGRAY, 0x07
.set COLOR_DGRAY, 0x08
.set COLOR_LBLUE, 0x09
.set COLOR_LGREEN, 0x0a
.set COLOR_LCYAN, 0x0b
.set COLOR_LRED, 0x0c
.set COLOR_LMAGENTA, 0x0d
.set COLOR_YELLOW, 0x0e
.set COLOR_WHITE, 0x0f
