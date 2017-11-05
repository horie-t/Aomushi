void io_hlt(void);
void io_cli(void);
void io_out8(int port, int data);
int io_load_eflags(void);
void io_store_eflags(int eflags);

void init_pallete(void);
void set_pallete(int start, int end, unsigned char *rgb);
void boxfill8(unsigned char *vram, int xsize, unsigned char c, int x0, int y0, int x1, int y1);

#define COL8_000000	0
#define COL8_FF0000	1
#define COL8_00FF00	2
#define COL8_FFFF00	3
#define COL8_0000FF	4
#define COL8_FF00FF	5
#define COL8_00FFFF	6
#define COL8_FFFFFF	7
#define COL8_C6C6C6	8
#define COL8_840000	9
#define COL8_008400	10
#define COL8_848400	11
#define COL8_000084	12
#define COL8_840084	13
#define COL8_008484	14
#define COL8_848484	15

void HariMain(void)
{
  int i;
  char *p;

  init_pallete();

  p = (char *)0xa0000;

  boxfill8(p, 320, COL8_FF0000,  20,  20, 120, 120);
  boxfill8(p, 320, COL8_00FF00,  70,  50, 170, 150);
  boxfill8(p, 320, COL8_0000FF, 120,  80, 220, 180);
  
  for (;;) {
    io_hlt();
  }
}

  unsigned char table_rgb[16 * 3] = {
    0x00, 0x00, 0x00,	/* 黒 */
    0xff, 0x00, 0x00,	/* 明るい赤 */
    0x00, 0xff, 0x00,	/* 明るい緑 */
    0xff, 0xff, 0x00,	/* 明るい黄色 */
    0x00, 0x00, 0xff,	/* 明るい青 */
    0xff, 0x00, 0xff,	/* 明るい紫 */
    0x00, 0xff, 0xff,	/* 明るい水色 */
    0xff, 0xff, 0xff,	/* 白 */
    0xc6, 0xc6, 0xc6,	/* 明るい灰色 */
    0x84, 0x00, 0x00,	/* 暗い赤 */
    0x00, 0x84, 0x00,	/* 暗い緑 */
    0x84, 0x84, 0x00,	/* 暗い黄色 */
    0x00, 0x00, 0x84,	/* 暗い青 */
    0x84, 0x00, 0x84,	/* 暗い紫 */
    0x00, 0x84, 0x84,	/* 暗い水色 */
    0x84, 0x84, 0x84,	/* 暗い灰色 */
  };

void init_pallete(void)
{

  set_pallete(0, 15, table_rgb);

  return;
}

void set_pallete(int start, int end, unsigned char *rgb)
{
  int i, eflags;
  eflags = io_load_eflags();
  io_cli();
  
  io_out8(0x03c8, start);
  for (i = start; i <= end; i++) {
    io_out8(0x03c9, rgb[0] / 4);
    io_out8(0x03c9, rgb[1] / 4);
    io_out8(0x03c9, rgb[2] / 4);
    rgb += 3;
  }
  
  io_store_eflags(eflags);
  return;
}

void boxfill8(unsigned char *vram, int xsize, unsigned char c, int x0, int y0, int x1, int y1)
{
  int x, y;
  for (y = y0; y <= y1; y++) {
    for (x = x0; x <= x1; x++)
      vram[y * xsize + x] = c;
  }
  return;
}
