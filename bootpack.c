void io_hlt(void);
void io_cli(void);
void io_out8(int port, int data);
int io_load_eflags(void);
void io_store_eflags(int eflags);

void init_pallete(void);
void set_pallete(int start, int end, unsigned char *rgb);

void HariMain(void)
{
  int i;
  char *p;

  init_pallete();

  p = (char *)0xa0000;
  for (i = 0; i <= 0xffff; i++) {
    p[i] = i & 0xf;
  }

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
