void io_halt();

void HariMain(void)
{
 fin:
  io_halt();
  goto fin;
}
