#include "bootpack.h"

#define PIT_CTRL	0x0043
#define PIT_CNT0	0x0040

#define TIMER_FLAGS_ALLOC	1 /* 確保した状態 */
#define TIMER_FLAGS_USING	2 /* タイマー作動中 */

struct TIMERCTL timerctl;

void init_pit(void)
{
  int i;
  
  io_out8(PIT_CTRL, 0x34);
  io_out8(PIT_CNT0, 0x9c);
  io_out8(PIT_CNT0, 0x2e);
  timerctl.count = 0;
  for (i = 0; i < MAX_TIMER; i++) {
    timerctl.timer[i].flags = 0; /* 未使用 */
  }
  return;
}

struct TIMER *timer_alloc(void)
{
  int i;
  for (i = 0; i < MAX_TIMER; i++) {
    if (timerctl.timer[i].flags == 0) {
      timerctl.timer[i].flags = TIMER_FLAGS_ALLOC;
      return &timerctl.timer[i];
    }
  }
  return 0;
}

void timer_free(struct TIMER *timer)
{
  timer->flags = 0;		/* 未使用 */
  return;
}

void timer_init(struct TIMER *timer, struct FIFO8 *fifo, unsigned char data)
{
  timer->fifo = fifo;
  timer->data = data;
  return;
}

void timer_settime(struct TIMER *timer, unsigned int timeout)
{
  timer->timeout = timeout + timerctl.count;
  timer->flags = TIMER_FLAGS_USING;
  return;
}

void inthandler20(int *esp)
{
  int i;
  
  io_out8(PIC0_OCW2, 0x60);	/* IRQ-00受付完了をPICに通知 */
  timerctl.count++;

  for (i = 0; i < MAX_TIMER; i++) {
    if (timerctl.timer[i].flags = TIMER_FLAGS_USING) {
      if (timerctl.timer[i].timeout <= timerctl.count) {
	timerctl.timer[i].flags = TIMER_FLAGS_ALLOC;
	fifo8_put(timerctl.timer[i].fifo, timerctl.timer[i].data);
      }
    }
  }
  
  return;
}
