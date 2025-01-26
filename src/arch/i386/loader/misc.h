/* LGOS i386 loader misc header file */

/** @file misc.h
* LGOS loader misc.h file
*/

#ifndef _misc_h
#define _misc_h

#include <stdint.h>

void halt(const char *msg, ...) __attribute__ ((noreturn));

char *ltoa(uint32_t val, char *buf, unsigned int radix);
uint32_t atol(const char *buf) __attribute__ ((pure));
int strlen(const char *s) __attribute__ ((pure));

#endif
