/* LGOS i386 loader video C file */

#include "video.h"

#define VID_INT 0x10            // video interrupt
#define VID_GETMODE 0x0f        // get video mode and active page

static char vidpage;            // current video page

void init_video(void) {
  __asm__ __volatile__ (
        "xorb   %%bh, %%bh\n"
        "int    %[vid_int]\n"
        "nop"
        : "+b" (vidpage)
        : "a" ((char)VID_GETMODE), [vid_int] "i" (VID_INT)
        :
  );
  if (vidpage) {        //////////
    return;             //////////
  }                     //////////
}

/*
.global init_video
init_video:
        xorb    %bh, %bh        // BIOS bug
        movb    $VID_GETMODE, %ah
        int     $VID_INT
        movb    %bh, vpg
        retw
*/
