/* LGOS i386 loader main C file */

#include "video.h"
#include "misc.h"

void main(void) __attribute__ ((noreturn));

void main(void) {
  init_video();

  //////////////////////////////////////
  setcolor(CLR_BLACK, CLR_YELLOW);
  print("alma\n");
  setcolorf(CLR_LBLUE);
  locate(9, 4);
  print("korte\n");
  setcolorf(CLR_MAGENTA);
  print("citrom\rCR\n");

  setcolor(CLR_BLUE, CLR_YELLOW);
  char buf[20];
  ltoa(12345, buf, 10);
  print(buf);
  print("\n");
  setcolor(CLR_GREEN, CLR_YELLOW);
  ltoa(0x1abc, buf, 16);
  print(buf);
  print("\n");
  setcolor(CLR_MAGENTA, CLR_YELLOW);
  ltoa(01234567, buf, 8);
  print(buf);
  print("\n");

  setcolor(CLR_BLACK, CLR_LGREEN);
  char buf2[20] = "alma";
  unsigned long int q = strlen(buf2);
  ltoa(q, buf, 10);
  print(buf);
  print("\n");

  char *c = buf2;
  setcolor(CLR_BLACK, CLR_LGREEN);
  c[2] = 0;
  q = strlen(buf2);
  ltoa(q, buf, 10);
  print(buf);
  print("\n");

  setcolorf(CLR_RED);
  q = (unsigned long int)atol("  1024aa23");
  ltoa(q, buf, 10);
  print(buf);
  print("\n");


  setcolorf(CLR_YELLOW);

  printf("Alma %%, 2: %03hhd,\n\
3: %4hi;\n\
4:%lu,\n\
5: %llx,\n\
0x123A: %lx,\n\
0X1DEF: %lX,\n\
szoveg Q: %c,\n\
korte: %s\n",
    (char)2, (int)(3), (unsigned long int)4, (unsigned long long int)0x123456789abcdef0, (long int)0x123a, (long int)0x1def, 'Q', "korte");
  //////////////////////////////////////


  halt();
}
