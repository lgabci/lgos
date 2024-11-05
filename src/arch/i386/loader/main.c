/* LGOS i386 loader main C file */

#include "video.h"
#include "misc.h"

void main(void) __attribute__ ((noreturn));

void main(void) {
  init_video();

  //////////////////////////////////////
  setcolorf(CLR_YELLOW);

  printf("Alma %C%%%C, 2: \"%03hhd\",\n\
3: \"%4hi\";\n\
4: \"%lu\",\n\
5: %llx,\n\
0x123A: %lx,\n\
0X1DEF: %lX,\n\
szoveg Q: %c,\n\
korte: %s\n",
    (char)(CLR_BLUE << 4 | CLR_LGREEN),
    (char)(CLR_BLACK << 4 | CLR_LMAGENTA),
    (char)2, (int)(3), (unsigned long int)4, (unsigned long long int)0x123456789abcdef0, (long int)0x123a, (long int)0x1def, 'Q', "korte");
  //////////////////////////////////////


  halt();
}
