void io_halt();
void write_mem8(int addr, int data);

void HariMain(void)
{
  int i;
  char *p;

  for (i = 0xa0000; i <= 0xaffff; i++) {
    p = i;
    *p = i & 0xf;
  }

  for (;;) {
    io_halt();
  }
}
