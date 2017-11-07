#include "bootpack.h"

void init_pic(void)
{
  io_out8(PIC0_IMR, 0xff);	/* 全ての割り込みを受け付けない */
  io_out8(PIC1_IMR, 0xff);	/* 全ての割り込みを受け付けない */
  
  io_out8(PIC0_ICW1, 0x11  );	/* エッジ・トリガー・モード */
  io_out8(PIC0_ICW2, 0x20  );	/* IRQ0-7は、INT20-27で受け取る */
  io_out8(PIC0_ICW3, 1 << 2);	/* PIC1は、IRQ2にて接続 */
  io_out8(PIC0_ICW4, 0x01  );	/* ノン・バッファ・モード */
  
  io_out8(PIC1_ICW1, 0x11  );	/* エッジ・トリガー・モード */
  io_out8(PIC1_ICW2, 0x28  );	/* IRQ8-15は、INT28-2fで受け取る */
  io_out8(PIC1_ICW3, 2     );	/* PIC1は、IRQ2にて接続 */
  io_out8(PIC1_ICW4, 0x01  );	/* ノン・バッファ・モード */
  
  io_out8(PIC0_IMR, 0xfb);	/* 11111011 PIC1以外は禁止 */
  io_out8(PIC1_IMR, 0xff);	/* 11111111 全ての割り込みを受け付けない */

  return;
}

void inthandler27(int *esp)
{
  io_out8(PIC0_OCW2, 0x67);	/* IRQ-07受付完了をPICに通知*/
  return;
}
