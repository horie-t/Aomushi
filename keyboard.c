#include "bootpack.h"

struct FIFO8 keyfifo;

void wait_KBC_sendready(void)
{
  /* キーボード・コントローラがデータ送信可能になるまで待つ */
  for (;;) {
    if ((io_in8(PORT_KEYSTA) & KEYSTA_SEND_NOTREADY) == 0) {
      break;
    }
  }
  return;
}

void init_keyboard(void)
{
  /* キーボード・コントローラの初期化 */
  wait_KBC_sendready();
  io_out8(PORT_KEYCMD, KEYCMD_WRITE_MODE);
  wait_KBC_sendready();
  io_out8(PORT_KEYDAT, KBC_MODE);
  return;
}

void inthandler21(int *esp)
{
  struct BOOTINFO *binfo = (struct BOOTINFO *) ADR_BOOTINFO;
  unsigned char data;

  io_out8(PIC0_OCW2, 0x61);	/* IRQ-01受付完了をPICに通知 */
  data = io_in8(PORT_KEYDAT);
  fifo8_put(&keyfifo, data);
  return;
}

