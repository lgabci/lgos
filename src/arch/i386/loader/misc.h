/* LGOS i386 loader misc header file */

#ifndef __misc_h__
#define __misc_h__

void halt(void) __attribute__ ((noreturn));
char *ltoa(unsigned long int val, char *buf, unsigned int radix);
unsigned long int atol(const char *buf) __attribute__ ((pure));
unsigned long int strlen(const char *s) __attribute__ ((pure));

#endif
