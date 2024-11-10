/* LGOS i386 loader main C file */

#include "video.h"
#include "misc.h"

void main(void) __attribute__ ((noreturn));

void main(void) {
  init_video();

  setcolor(CLR_BLACK, CLR_WHITE);
  printf("LGOS Loader.\n");


  halt();
}
