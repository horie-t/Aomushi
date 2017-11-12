#include "bootpack.h"

#define PIT_CTRL	0x0043
#define PIT_CNT0	0x0040

#define TIMER_FLAGS_ALLOC	1 /* 確保した状態 */
#define TIMER_FLAGS_USING	2 /* タイマー作動中 */

struct TIMERCTL timerctl;

void init_pit(void)
{
  int i;
  struct TIMER *t;
  
  io_out8(PIT_CTRL, 0x34);
  io_out8(PIT_CNT0, 0x9c);
  io_out8(PIT_CNT0, 0x2e);
  timerctl.count = 0;
  for (i = 0; i < MAX_TIMER; i++) {
    timerctl.timers0[i].flags = 0; /* 未使用 */
  }
  t = timer_alloc();
  t->timeout = 0xffffffff;
  t->flags = TIMER_FLAGS_USING;
  timerctl.t0 = t;
  timerctl.next = 0xffffffff;
  return;
}

struct TIMER *timer_alloc(void)
{
  int i;
  for (i = 0; i < MAX_TIMER; i++) {
    if (timerctl.timers0[i].flags == 0) {
      timerctl.timers0[i].flags = TIMER_FLAGS_ALLOC;
      return &timerctl.timers0[i];
    }
  }
  return 0;
}

void timer_free(struct TIMER *timer)
{
  timer->flags = 0;		/* 未使用 */
  return;
}

void timer_init(struct TIMER *timer, struct FIFO32 *fifo, int data)
{
  timer->fifo = fifo;
  timer->data = data;
  return;
}

void timer_settime(struct TIMER *timer, unsigned int timeout)
{
  int e;
  struct TIMER *t, *s;
  
  timer->timeout = timeout + timerctl.count;
  timer->flags = TIMER_FLAGS_USING;

  e = io_load_eflags();
  io_cli();
  
  t = timerctl.t0;
  if (timer->timeout <= t->timeout) {
    /* 先頭に入れる場合 */
    timerctl.t0 = timer;
    timer->next = t;		/* 次はt */
    timerctl.next = timer->timeout;
    io_store_eflags(e);
    return;
  }    
  /* どこに入れればいいかを探す */
  for (;;) {
    s = t;
    t = t->next;
    if (t == 0) {
      break;			/* 一番後ろに入れる事になった */
    }
    if (timer->timeout <= t->timeout) {
      /* sとtの間に入れる事になった */
      s->next = timer;
      timer->next = t;
      io_store_eflags(e);
      return;
    }
  }

  return;
}

void inthandler20(int *esp)
{
  struct TIMER *timer;
  
  io_out8(PIC0_OCW2, 0x60);	/* IRQ-00受付完了をPICに通知 */
  timerctl.count++;
  if (timerctl.next > timerctl.count) {
    return;
  }

  timer = timerctl.t0;	/* とりあえず先頭の番地をtimerに代入 */
  for (;;) {
    /* timersのタイマーは全て動作中のものなので、flagsを確認しない */
    if (timer->timeout > timerctl.count) {
      break;
    }
    /* タイムアウト */
    timer->flags = TIMER_FLAGS_ALLOC;
    fifo32_put(timer->fifo, timer->data);
    timer = timer->next;
  }
  
  timerctl.t0 = timer;
  timerctl.next = timerctl.t0->timeout;

  return;
}
