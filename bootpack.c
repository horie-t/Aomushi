#include <stdarg.h>

#include "lib/aolib.h"
#include "bootpack.h"

void HariMain(void)
{
  struct BOOTINFO *binfo = (struct BOOTINFO *) ADR_BOOTINFO;
  char mcursor[16 * 16];
  char msg[256];
  int mx = 152;
  int my = 78;

  init_gdtidt();
  init_pallete();
  init_screen(binfo->vram, binfo->scrnx, binfo->scrny);
  init_mouse_cursor8(mcursor, COL8_008484);
  
  sprintk(msg, "(%d, %d)", mx, my);
  putfonts8_asc(binfo->vram, binfo->scrnx, 0, 0, COL8_FFFFFF, msg);
  
  putblock8_8(binfo->vram, binfo->scrnx, 16, 16, mx, my, mcursor, 16);
  
  for (;;) {
    io_hlt();
  }
}
