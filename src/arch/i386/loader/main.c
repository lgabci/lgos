/* LGOS i386 loader main C file */

#include <stdint.h>

#include "video.h"
#include "misc.h"
#include "disk.h"

void main(void) __attribute__ ((noreturn));

void main(void) {
  init_video();

  setcolor(CLR_BLACK, CLR_WHITE);
  printf("LGOS Loader.\n");

  init_disk();



  halt("No kernel loaded.");
}
