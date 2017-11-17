void api_putstr0(char *s);
void api_exit(void);

void HariMain(void)
{
  api_putstr0("hello, world.\n");
  api_end();
}
