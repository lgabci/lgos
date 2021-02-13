.arch i8086,nojumps
.code16

.if 0
.doxygen-begin
/**
 * @file video_inc.s
 * @brief i386 video functions include file
 */
.doxygen-end
.endif

.if 0
.doxygen-begin
/**
 * @def COLOR_BLACK
 * @brief background and foreground black color
 */
/**
 * @def COLOR_BLUE
 * @brief background and foreground blue color
 */
/**
 * @def COLOR_GREEN
 * @brief background and foreground green color
 */
/**
 * @def COLOR_CYAN
 * @brief background and foreground cyan color
 */
/**
 * @def COLOR_RED
 * @brief background and foreground red color
 */
/**
 * @def COLOR_MAGENTA
 * @brief background and foreground magenta color
 */
/**
 * @def COLOR_BROWN
 * @brief background and foreground brown color
 */
/**
 * @def COLOR_LGRAY
 * @brief background and foreground light gray color
 */
/**
 * @def COLOR_DGRAY
 * @brief foreground dark gray color
 */
/**
 * @def COLOR_LBLUE
 * @brief foreground light blue color
 */
/**
 * @def COLOR_LGREEN
 * @brief foreground light green color
 */
/**
 * @def COLOR_LCYAN
 * @brief foreground light cyan color
 */
/**
 * @def COLOR_LRED
 * @brief foreground light red color
 */
/**
 * @def COLOR_LMAGENTA
 * @brief foreground light magenta color
 */
/**
 * @def COLOR_YELLOW
 * @brief foreground yellow color
 */
/**
 * @def COLOR_WHITE
 * @brief foreground white color
 */
.doxygen-end
.endif

.set COLOR_BLACK,    0x00
.set COLOR_BLUE,     0x01
.set COLOR_GREEN,    0x02
.set COLOR_CYAN,     0x03
.set COLOR_RED,      0x04
.set COLOR_MAGENTA,  0x05
.set COLOR_BROWN,    0x06
.set COLOR_LGRAY,    0x07
.set COLOR_DGRAY,    0x08
.set COLOR_LBLUE,    0x09
.set COLOR_LGREEN,   0x0a
.set COLOR_LCYAN,    0x0b
.set COLOR_LRED,     0x0c
.set COLOR_LMAGENTA, 0x0d
.set COLOR_YELLOW,   0x0e
.set COLOR_WHITE,    0x0f
