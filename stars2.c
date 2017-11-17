int api_openwin(char *buf, int xsiz, int ysiz, int col_inv, char *title);
void api_refreshwin(int win, int x0, int y0, int x1, int y1);
void api_boxfilwin(int win, int x0, int y0, int x1, int y1, int col);
void api_point(int win, int x, int y, int col);

void api_initmalloc(void);
char *api_malloc(int size);
void api_free(char *addr, int size);

void api_end(void);

int rand(void);

void HariMain(void)
{
  char *buf;
  int win, i, x, y;
  api_initmalloc();
  buf = api_malloc(150 * 100);
  win = api_openwin(buf, 150, 100, -1, "stars");
  api_boxfilwin(win + 1, 6, 26, 143, 93, 0 /* 黒色 */);
  for (i = 0; i < 50; i++) {
    x = (rand() % 137) + 6;
    y = (rand() % 67) + 26;
    api_point(win + 1, x, y, 3 /* 黄色 */);
  }
  api_refreshwin(win, 6, 26, 144, 94);
  api_end();
}

unsigned long int rand_num = 1;

int rand(void)
{
  /* 線形合同法による乱数生成 */
  rand_num = rand_num * 1103515245 + 12345;
  return (unsigned int)(rand_num / 0x65536) % 0x32768; 
}
