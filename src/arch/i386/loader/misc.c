/* LGOS i386 loader misc C file */

#include "misc.h"

void halt(void) {
  while (1) {
    __asm__ __volatile__ (
        "hlt"
    );
  }
}

char *ltoa(unsigned long int val, char *buf, unsigned int radix) {
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

unsigned long int atol(const char *buf) {
  unsigned long int i = 0;

  for ( ; *buf == ' '; buf ++) ;
  for ( ; *buf >= '0' && *buf <= '9'; buf ++) {
    i = i * 10 + (unsigned char)*buf - '0';
  }

  return i;
}

unsigned long int strlen(const char *s) {
  unsigned long int i;

  for(i = 0; s[i]; i ++) ;
  return i;
}
