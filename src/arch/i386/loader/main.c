/* LGOS i386 loader main C file */

/** @file main.c
* LGOS loader main.c file
*/
#include <stdint.h>

#include "video.h"
#include "misc.h"
#include "disk.h"

extern void *BSS_START;
extern void *BSS_END;

void main(void) __attribute__ ((noreturn));

void main(void) {
  init_video();
  setcolor(CLR_BLACK, CLR_WHITE);
  printf("LGOS Loader.\n");

  init_disk();



  halt("No kernel loaded.");
}
