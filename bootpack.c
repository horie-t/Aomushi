#include <stdarg.h>

#include "lib/aolib.h"
#include "bootpack.h"

extern struct FIFO8 keyfifo, mousefifo;
extern struct TIMERCTL timerctl;

void make_window8(unsigned char *buf, int xsize, int ysize, char *title)
{
  static char closebtn[14][16] = {
    "OOOOOOOOOOOOOOO@",
    "OQQQQQQQQQQQQQ$@",
    "OQQQQQQQQQQQQQ$@",
    "OQQQ@@QQQQ@@QQ$@",
    "OQQQQ@@QQ@@QQQ$@",
    "OQQQQQ@@@@QQQQ$@",
    "OQQQQQQ@@QQQQQ$@",
    "OQQQQQ@@@@QQQQ$@",
    "OQQQQ@@QQ@@QQQ$@",
    "OQQQ@@QQQQ@@QQ$@",
    "OQQQQQQQQQQQQQ$@",
    "OQQQQQQQQQQQQQ$@",
    "O$$$$$$$$$$$$$$@",
    "@@@@@@@@@@@@@@@@",
  };

  int x, y;
  char c;
  
  boxfill8(buf, xsize, COL8_C6C6C6,         0,         0, xsize - 1,         0);
  boxfill8(buf, xsize, COL8_FFFFFF,         1,         1, xsize - 2,         1);
  boxfill8(buf, xsize, COL8_C6C6C6,         0,         0,         0, ysize - 1);
  boxfill8(buf, xsize, COL8_FFFFFF,         1,         1,         1, ysize - 2);
  boxfill8(buf, xsize, COL8_848484, xsize - 2,         1, xsize - 2, ysize - 2);
  boxfill8(buf, xsize, COL8_000000, xsize - 1,         0, xsize - 1, ysize - 1);
  boxfill8(buf, xsize, COL8_C6C6C6,         2,         2, xsize - 3, ysize - 3);
  boxfill8(buf, xsize, COL8_000084,         3,         3, xsize - 4,        20);
  boxfill8(buf, xsize, COL8_848484,         1, ysize - 2, xsize - 2, ysize - 2);
  boxfill8(buf, xsize, COL8_000000,         0, ysize - 1, xsize - 1, ysize - 1);
  putfonts8_asc(buf, xsize, 24, 4, COL8_FFFFFF, title);
  
  for (y = 0; y < 14; y++) {
    for (x = 0; x < 16; x++) {
      c = closebtn[y][x];
      if (c == '@') {
	c = COL8_000000;
      } else if (c == '$') {
	c = COL8_848484;
      } else if (c == 'Q') {
	c = COL8_C6C6C6;
      } else {
	c = COL8_FFFFFF;
      }
      buf[(5 + y) * xsize + (xsize - 21 + x)] = c;
    }
  }
  return;
}

void HariMain(void)
{
  struct BOOTINFO *binfo = (struct BOOTINFO *) ADR_BOOTINFO;
  struct FIFO32 fifo;
  int fifobuf[128];
  char msg[256], s[40];
  struct TIMER *timer, *timer2, *timer3;
  int mx, my;
  int i;
  
  struct MOUSE_DEC mdec;

  unsigned int memtotal;
  struct MEMMAN *memman = (struct MEMMAN *) MEMMAN_ADDR;

  struct SHTCTL *shtctl;
  struct SHEET *sht_back, *sht_win, *sht_mouse;
  unsigned char *buf_back, *buf_win, buf_mouse[256];


  init_gdtidt();
  init_pic();
  io_sti();	/* IDT/PICの初期化が完了したので、CPUの割り込み禁止を解除 */
  
  fifo32_init(&fifo, 128, fifobuf);
  init_pit();
  io_out8(PIC0_IMR, 0xf8); /* PITとPIC1とキーボードを許可(1111100) */
  io_out8(PIC1_IMR, 0xef); /* マウスを許可(11101111) */

  timer = timer_alloc();
  timer_init(timer, &fifo, 10);
  timer_settime(timer, 1000);

  timer2 = timer_alloc();
  timer_init(timer2, &fifo, 3);
  timer_settime(timer2, 300);

  timer3 = timer_alloc();
  timer_init(timer3, &fifo, 1);
  timer_settime(timer3, 50);
  
  init_keyboard(&fifo, 128);
  enable_mouse(&fifo, 512, &mdec);
  
  memtotal = memtest(0x00400000, 0xbfffffff);
  memman_init(memman);
  memman_free_4k(memman, 0x00001000, 0x0009e000);
  memman_free_4k(memman, 0x00400000, memtotal - 0x00400000);
  
  init_pallete();
  shtctl = shtctl_init(memman, binfo->vram, binfo->scrnx, binfo->scrny);
  
  sht_back = sheet_alloc(shtctl);
  sht_mouse = sheet_alloc(shtctl);
  sht_win = sheet_alloc(shtctl);
  
  buf_back = (unsigned char *)memman_alloc_4k(memman, binfo->scrnx * binfo->scrny);
  buf_win = (unsigned char *)memman_alloc_4k(memman, 160 * 52);
  sheet_setbuf(sht_back, buf_back, binfo->scrnx, binfo->scrny, -1);
  sheet_setbuf(sht_mouse, buf_mouse, 16, 16, 99);
  sheet_setbuf(sht_win, buf_win, 160, 52, -1); /* 透明色なし */
  
  init_screen8(buf_back, binfo->scrnx, binfo->scrny);
  init_mouse_cursor8(buf_mouse, 99); /* 背景色は99 */
  make_window8(buf_win, 160, 52, "counter");
  
  sheet_slide(sht_back, 0, 0);
  mx = (binfo->scrnx - 16) / 2;	/* 画面中央になるように座標計算 */
  my = (binfo->scrny - 28 - 16) / 2;
  sheet_slide(sht_mouse, mx, my);
  sheet_slide(sht_win, 80, 72);
  
  sheet_updown(sht_back, 0);
  sheet_updown(sht_win, 1);
  sheet_updown(sht_mouse, 2);

  sprintk(msg, "(%d, %d)", mx, my);
  putfonts8_asc(buf_back, binfo->scrnx, 0, 0, COL8_FFFFFF, msg);
  
  sprintk(msg, "memory %dMB   free : %dKB",
	  memtotal / (1024 * 1024), memman_total(memman) / 1024);
  putfonts8_asc(buf_back, binfo->scrnx, 0, 32, COL8_FFFFFF, msg);
  sheet_refresh(sht_back, 0, 0, binfo->scrnx, 48);
  
  for (;;) {
    sprintk(s, "%010d", timerctl.count);
    putfonts8_asc_sht(sht_win, 40, 28, COL8_000000, COL8_C6C6C6, s, 10);
    
    io_cli();
    if (fifo32_status(&fifo) == 0) {
      io_sti();
    } else {
      i = fifo32_get(&fifo);
      io_sti();
      
      if (256 <= i && i <= 511) {
	sprintk(s, "%02X", i - 256);
	putfonts8_asc_sht(sht_back, 0, 16, COL8_FFFFFF, COL8_008484, s, 2);
      } else if (512 <= i && i <= 767) {
	if (mouse_decode(&mdec, i - 512) != 0) {
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
	  putfonts8_asc_sht(sht_back, 32, 16, COL8_FFFFFF, COL8_008484, s, 15);

	  /* マウス・カーソルの移動 */
	  mx += mdec.x;
	  my += mdec.y;
	  if (mx < 0) {
	    mx = 0;
	  }
	  if (my < 0) {
	    my = 0;
	  }
	  if (mx > binfo->scrnx - 1) {
	    mx = binfo->scrnx - 1;
	  }
	  if (my > binfo->scrny - 1) {
	    my = binfo->scrny - 1;
	  }
	  sprintk(msg, "(%3d, %3d)", mx, my);
	  putfonts8_asc_sht(sht_back, 0, 0, COL8_FFFFFF, COL8_008484, msg, 10);
	  sheet_slide(sht_mouse, mx, my); /* sheet_refreshを含む */
	}
      } else if (i == 10) {
	putfonts8_asc(buf_back, binfo->scrnx, 0, 64, COL8_FFFFFF, "10[sec]");
	sheet_refresh(sht_back, 0, 64, 56, 80);
      } else if (i == 3) {
	putfonts8_asc(buf_back, binfo->scrnx, 0, 80, COL8_FFFFFF, "3[sec]");
	sheet_refresh(sht_back, 0, 80, 56, 96);
      } else if (i == 1) {
	timer_init(timer3, &fifo, 0); /* 次は0を */
	boxfill8(buf_back, binfo->scrnx, COL8_FFFFFF, 8, 96, 15, 111);
	timer_settime(timer3, 50);
	sheet_refresh(sht_back, 8, 96, 16, 112);
      } else if (i == 0) {
	timer_init(timer3, &fifo, 1); /* 次は1を */
	boxfill8(buf_back, binfo->scrnx, COL8_008484, 8, 96, 15, 111);
	timer_settime(timer3, 50);
	sheet_refresh(sht_back, 8, 96, 16, 112);
      }
    }
  }
}
