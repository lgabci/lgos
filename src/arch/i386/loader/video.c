/* LGOS i386 loader video C file */

#include <stdarg.h>
#include "video.h"
#include "misc.h"

#define VID_INT         0x10    // video interrupt
#define VID_GETCURPOS   0x03    // get cursor position
#define VID_SETCURPOS   0x02    // set cursor position
#define VID_SCROLLUP    0x06    // scroll up window
#define VID_WRTCHR      0x09    // write char and attribute
#define VID_GETMODE     0x0f    // get video mode and active page

static unsigned char vidpage;   // current video page
static unsigned char color;     // current video color

static unsigned char maxcol;    // max number of columns, 0 based
static unsigned char maxrow;    // max number of rows, 0 based
static unsigned char col;       // actual column, 0 based
static unsigned char row;       // actual row, 0 based

void get_curpos(void);
void set_curpos(void);
void scrollup(unsigned char rows);

void init_video(void) {
  __asm__ __volatile__ (
        "movb   %[vid_getmode], %%ah\n"
        "int    %[vid_int]\n"
        "movb   %%bh, %[vidpage]\n"
        "movb   %%ah, %[maxcol]\n"
        : [vidpage]     "=m" (vidpage),
          [maxcol]      "=m" (maxcol)
        : [vid_getmode] "i"  (VID_GETMODE),
          [vid_int]     "i"  (VID_INT)
        : "ax", "bh"
  );

  maxcol --;
  maxrow = 25 - 1;
  color = CLR_LGRAY;
  get_curpos();
}

void get_curpos(void) {
  __asm__ __volatile__ (
        "movb   %[vid_getcurpos], %%ah\n"
        "movb   %[vidpage], %%bh\n"
        "int    %[vid_int]\n"
        "movb   %%dh, %[row]\n"
        "movb   %%dl, %[col]\n"
        : [row]           "=m" (row),
          [col]           "=m" (col)
        : [vid_getcurpos] "i"  (VID_GETCURPOS),
          [vidpage]       "m"  (vidpage),
          [vid_int]       "i"  (VID_INT)
        : "ax", "bh", "cx", "dx"
  );
}

void set_curpos(void) {
  __asm__ __volatile__ (
        "movb   %[vid_setcurpos], %%ah\n"
        "movb   %[vidpage], %%bh\n"
        "movb   %[row], %%dh\n"
        "movb   %[col], %%dl\n"
        "int    %[vid_int]\n"
        :
        : [vid_setcurpos] "i" (VID_SETCURPOS),
          [vidpage]       "m" (vidpage),
          [row]           "m" (row),
          [col]           "m" (col),
          [vid_int]       "i" (VID_INT)
        : "ah", "bh", "dx"
  );
}

void scrollup(unsigned char rows) {
  __asm__ __volatile__ (
        "movb   %[vid_scrollup], %%ah\n"
        "movb   %[rows], %%al\n"
        "movb   %[color], %%bh\n"
        "xorw   %%cx, %%cx\n"
        "movb   %[maxrow], %%dh\n"
        "movb   %[maxcol], %%dl\n"
        "pushw  %%bp\n"
        "int    %[vid_int]\n"
        "popw   %%bp\n"
        :
        : [vid_scrollup]  "i" (VID_SCROLLUP),
          [rows]          "m" (rows),
          [color]         "m" (color),
          [maxrow]        "m" (maxrow),
          [maxcol]        "m" (maxcol),
          [vid_int]       "i" (VID_INT)
        : "ax", "bh", "cx", "dx"
  );
}

void setcolor(unsigned char bg, unsigned char fg) {
  color = (unsigned char)((bg & 0x07) << 4 | fg);
}

void setcolorf(unsigned char fg) {
  color = (color & 0x70) | fg;
}

void locate(unsigned char r, unsigned char c) {
  if (r <= maxrow && c <= maxcol) {
    row = r;
    col = c;
    set_curpos();
  }
}

void print_chr(const char chr) {
  switch (chr) {
    case '\n':
      col = 0;
      row ++;
      break;
    case '\r':
      row ++;
      break;
    case '\t':
      col = (unsigned char)(((col >> 3) + 1) << 3);
      break;
    default:
    __asm__ __volatile__ (
          "movb   %[vid_wrtchr], %%ah\n"
          "movb   %[chr], %%al\n"
          "movb   %[vidpage], %%bh\n"
          "movb   %[color], %%bl\n"
          "movw   $1, %%cx\n"
          "int    %[vid_int]\n"
          :
          : [vid_wrtchr] "i" (VID_WRTCHR),
            [chr]        "m" (chr),
            [vidpage]    "m" (vidpage),
            [color]      "m" (color),
            [vid_int]    "i" (VID_INT)
          : "ax", "bx", "cx"
    );
    col ++;
    break;
  }

  if (col > maxcol) {
    col = 0;
    row ++;
  }

  if (row > maxrow) {
    scrollup((unsigned char)(row -  maxrow));
    row = maxrow;
  }
  set_curpos();
}

void print(const char *chr) {
  while (*chr) {
    print_chr(*chr ++);
  }
}

void printf(const char *format, ...) {
  int zerofill;
  int width;
  int len;

  va_list args;
  va_start(args, format);

  while (*format) {
    zerofill = 0;
    width = 0;
    len = 4;

    switch(*format) {
      case '%':
        format ++;
        switch(*format) {
          case '%':
            print_chr(*format ++);
            break;
          default:
            if (*format == '0') {       // flags
              zerofill = 1;
              format ++;
            }

            while (*format >= '0' && *format <= '9') {  // width
              width = width * 10 + *format - '0';
              format ++;
            }

            switch (*format) {          // length
              case 'h':
                len = 2;
                format ++;
                if (*format == 'h') {
                  len = 1;
                  format ++;
                }
                break;
              case 'l':
                len = 4;
                format ++;
                if (*format == 'l') {
                  len = 8;
                  format ++;
                }
                break;
              default:
              ;
            }

            switch (*format) {          // specifier
              case 'd':
              case 'i':
              case 'u':
              case 'o':
              case 'x':
              case 'X': ;
                char buf[20];
                unsigned int prefix;

                switch (*format) {
                  case 'o':
                    prefix = 8;
                    break;
                  case 'x':
                  case 'X': ;
                    prefix = 16;
                    break;
                  default:
                    prefix = 10;
                    break;
                }

                switch (len) {
                  case 1: ;
                    unsigned char c;
                    c = (unsigned char)va_arg(args, unsigned int);
                    ltoa(c, buf, prefix);
                    break;
                  case 2: ;
                    unsigned int i;
                    i = va_arg(args, unsigned int);
                    ltoa(i, buf, prefix);
                    break;
                  case 4: ;
                    unsigned long int l;
                    l = va_arg(args, unsigned long int);
                    ltoa(l, buf, prefix);
                    break;
                  case 8: ;
                    unsigned long long int ll;
                    ll = va_arg(args, unsigned long long int);
                    ltoa((unsigned long int)ll, buf, prefix);
                    break;
                  default:
                    break;
                }

                print(buf);

                if (zerofill) { };

                format ++;
                break;
              case 'c': ;
                char c;
                c = (char)va_arg(args, int);
                print_chr(c);
                format ++;
                break;
              case 's': ;
                char *s;
                s = va_arg(args, char *);
                print(s);
                format ++;
                break;
              default:
                break;
            }
            break;
        }
        break;
      default:
        print_chr(*format);
        format ++;
        break;
    }
  }
  va_end(args);
}
