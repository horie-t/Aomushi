#include <stdarg.h>

#include "lib/aolib.h"
#include "bootpack.h"

extern struct KEYBUF keybuf;

void HariMain(void)
{
  struct BOOTINFO *binfo = (struct BOOTINFO *) ADR_BOOTINFO;
  char mcursor[16 * 16];
  char msg[256], s[4];
  int mx;
  int my;
  int i;

  init_gdtidt();
  init_pic();
  io_sti();	/* IDT/PICの初期化が完了したので、CPUの割り込み禁止を解除 */
  
  init_pallete();
  init_screen(binfo->vram, binfo->scrnx, binfo->scrny);
  init_mouse_cursor8(mcursor, COL8_008484);

  /* マウス・カーソルを画面中心になるように計算し描画 */
  mx = (binfo->scrnx - 16) / 2;
  my = (binfo->scrny - 28 - 16) / 2;
  putblock8_8(binfo->vram, binfo->scrnx, 16, 16, mx, my, mcursor, 16);
  
  sprintk(msg, "(%d, %d)", mx, my);
  putfonts8_asc(binfo->vram, binfo->scrnx, 0, 0, COL8_FFFFFF, msg);
  
  io_out8(PIC0_IMR, 0xf9); /* PIC1とキーボードを許可(11111001) */
  io_out8(PIC1_IMR, 0xef); /* マウスを許可(11101111) */
  
  for (;;) {
    io_cli();
    if (keybuf.len == 0) {
      io_stihlt();
    } else {
      i = keybuf.data[keybuf.next_r];
      keybuf.len--;
      keybuf.next_r++;
      if (keybuf.next_r == 32) {
	keybuf.next_r = 0;
      }
      io_sti();
      
      sprintk(s, "%02X", i);
      boxfill8(binfo->vram, binfo->scrnx, COL8_000000, 0, 16, 15, 31);
      putfonts8_asc(binfo->vram, binfo->scrnx, 0, 16, COL8_FFFFFF, s);
    }
  }
}
