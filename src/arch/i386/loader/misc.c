/* LGOS i386 loader misc C file */

/** @file misc.c
* LGOS loader misc.c file
*/

#include "misc.h"
#include "video.h"

void halt(const char *msg, ...) {
  va_list args;

  va_start(args, msg);
  setcolor(CLR_BLACK, CLR_RED);
  vprintf(msg, args);
  va_end(args);

  while (1) {
    __asm__ __volatile__ (
        "hlt"
    );
  }
}

char *ltoa(uint32_t val, char *buf, unsigned int radix) {
  int i;
  int j;

  i = 0;
  do {
    buf[i ++] = (char)(val % radix + (val % radix <= 9 ? '0' : 'A' - 10));

    val = val / radix;
  } while (val);
  buf[i] = 0;

  for (j = 0; j < i / 2; j ++) {
    char c;
    c = buf[j];
    buf[j] = buf[i - j - 1];
    buf[i - j - 1] = c;
  }

  return buf;
}

uint32_t atol(const char *buf) {
  uint32_t i = 0;

  for ( ; *buf == ' '; buf ++) ;
  for ( ; *buf >= '0' && *buf <= '9'; buf ++) {
    i = i * 10 + (unsigned char)*buf - '0';
  }

  return i;
}

int strlen(const char *s) {
  int i;

  for(i = 0; s[i]; i ++) ;
  return i;
}
