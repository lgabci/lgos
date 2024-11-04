/* LGOS i386 loader video header file */

#ifndef __video_h__
#define __video_h__

#define CLR_BLACK       0x00    /* text mode colors */
#define CLR_BLUE        0x01
#define CLR_GREEN       0x02
#define CLR_CYAN        0x03
#define CLR_RED         0x04
#define CLR_MAGENTA     0x05
#define CLR_BROWN       0x06
#define CLR_LGRAY       0x07
#define CLR_DGRAY       0x08
#define CLR_LBLUE       0x09
#define CLR_LGREEN      0x0a
#define CLR_LCYAN       0x0b
#define CLR_LRED        0x0c
#define CLR_LMAGENTA    0x0d
#define CLR_YELLOW      0x0e
#define CLR_WHITE       0x0f


void init_video(void);
void print_chr(const char chr);
void setcolor(unsigned char bg, unsigned char fg);
void setcolorf(unsigned char fg);
void locate(unsigned char r, unsigned char c);
void print(const char *chr);
void printf(const char *format, ...);

#endif
