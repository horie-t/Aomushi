#include <stdarg.h>

#include "lib/aolib.h"
#include "bootpack.h"

extern struct FIFO8 keyfifo, mousefifo;

void HariMain(void)
{
  struct BOOTINFO *binfo = (struct BOOTINFO *) ADR_BOOTINFO;
  char mcursor[16 * 16];
  char msg[256], s[16], keybuf[32], mousebuf[128];
  int mx, my;
  int i;
  
  struct MOUSE_DEC mdec;

  unsigned int memtotal;
  struct MEMMAN *memman = (struct MEMMAN *) MEMMAN_ADDR;

  init_gdtidt();
  init_pic();
  io_sti();	/* IDT/PICの初期化が完了したので、CPUの割り込み禁止を解除 */
  
  fifo8_init(&keyfifo, 32, keybuf);
  fifo8_init(&mousefifo, 128, mousebuf);
  io_out8(PIC0_IMR, 0xf9); /* PIC1とキーボードを許可(11111001) */
  io_out8(PIC1_IMR, 0xef); /* マウスを許可(11101111) */
  init_keyboard();
  
  init_pallete();
  init_screen(binfo->vram, binfo->scrnx, binfo->scrny);
  init_mouse_cursor8(mcursor, COL8_008484);

  /* マウス・カーソルを画面中心になるように計算し描画 */
  mx = (binfo->scrnx - 16) / 2;
  my = (binfo->scrny - 28 - 16) / 2;
  putblock8_8(binfo->vram, binfo->scrnx, 16, 16, mx, my, mcursor, 16);
  
  sprintk(msg, "(%d, %d)", mx, my);
  putfonts8_asc(binfo->vram, binfo->scrnx, 0, 0, COL8_FFFFFF, msg);

  enable_mouse(&mdec);

  memtotal = memtest(0x00400000, 0xbfffffff);
  memman_init(memman);
  memman_free_4k(memman, 0x00001000, 0x0009e000);
  memman_free_4k(memman, 0x00400000, memtotal - 0x00400000);
  sprintk(msg, "memory %dMB   free : %dKB",
	  memtotal / (1024 * 1024), memman_total(memman) / 1024);
  putfonts8_asc(binfo->vram, binfo->scrnx, 0, 32, COL8_FFFFFF, msg);
  
  for (;;) {
    io_cli();
    if (fifo8_status(&keyfifo) + fifo8_status(&mousefifo) == 0) {
      io_stihlt();
    } else {
      if (fifo8_status(&keyfifo) != 0) {
	i = fifo8_get(&keyfifo);
	io_sti();
      
	sprintk(s, "%02X", i);
	boxfill8(binfo->vram, binfo->scrnx, COL8_000000, 0, 16, 15, 31);
	putfonts8_asc(binfo->vram, binfo->scrnx, 0, 16, COL8_FFFFFF, s);
      } else if (fifo8_status(&mousefifo) != 0) {
	i = fifo8_get(&mousefifo);
	io_sti();

	if (mouse_decode(&mdec, i) != 0) {
	  /* データが3バイト揃ったので表示 */
	  sprintk(s, "[lcr %4d %4d]", mdec.buf[1], mdec.buf[2]);
	  if ((mdec.btn & 0x01) != 0) {
	    s[1] = 'L';
	  }
	  if ((mdec.btn & 0x02) != 0) {
	    s[3] = 'R';
	  }
	  if ((mdec.btn & 0x04) != 0) {
	    s[2] = 'C';
	  }
	  boxfill8(binfo->vram, binfo->scrnx, COL8_000000, 32, 16, 32 + 15 * 8 - 1, 31);
	  putfonts8_asc(binfo->vram, binfo->scrnx, 32, 16, COL8_FFFFFF, s);

	  /* マウス・カーソルの移動 */
	  boxfill8(binfo->vram, binfo->scrnx, COL8_008484, mx, my, mx + 15, my + 15); /* マウスを消す */
	  mx += mdec.x;
	  my += mdec.y;
	  if (mx < 0) {
	    mx = 0;
	  }
	  if (my < 0) {
	    my = 0;
	  }
	  if (mx > binfo->scrnx - 16) {
	    mx = binfo->scrnx - 16;
	  }
	  if (my > binfo->scrny - 16) {
	    my = binfo->scrny - 16;
	  }
	  sprintk(msg, "(%3d, %3d)", mx, my);
	  boxfill8(binfo->vram, binfo->scrnx, COL8_008484, 0, 0, 79, 15);	/* 座標を消す */
	  putfonts8_asc(binfo->vram, binfo->scrnx, 0, 0, COL8_FFFFFF, msg);	/* 座標を書く */
	  putblock8_8(binfo->vram, binfo->scrnx, 16, 16, mx, my, mcursor, 16);	/* マウスを描く */
	}
      }
    }
  }
}

