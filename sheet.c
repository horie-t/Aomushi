#include "bootpack.h"

#define SHEET_USE	1

struct SHTCTL *shtctl_init(struct MEMMAN *memman, unsigned char *vram, int xsize, int ysize)
{
  struct SHTCTL *ctl;
  int i;
  
  ctl = (struct SHTCTL *) memman_alloc_4k(memman, sizeof(struct SHTCTL));
  if (ctl == 0) {
    goto err;
  }

  ctl->vram = vram;
  ctl->xsize = xsize;
  ctl->ysize = ysize;
  ctl->top = -1;
  for (i = 0; i < MAX_SHEETS; i++) {
    ctl->sheets0[i].flags = 0;	/* 未使用マーク */
    ctl->sheets0[i].ctl = ctl;	/* 所属を記録 */
  }

 err:
  return ctl;
}

struct SHEET *sheet_alloc(struct SHTCTL *ctl)
{
  struct SHEET *sht;
  int i;
  for (i = 0; i < MAX_SHEETS; i++) {
    if (ctl->sheets0[i].flags == 0) {
      sht = &ctl->sheets0[i];
      sht->flags = SHEET_USE;	/* 使用中マーク */
      sht->height = -1;		/* 非表示中 */
      return sht;
    }
  }
  return 0;			/* 全てのシートが使用中だった */
}

void sheet_setbuf(struct SHEET *sht, unsigned char *buf, int xsize, int ysize, int col_inv)
{
  sht->buf = buf;
  sht->bxsize = xsize;
  sht->bysize = ysize;
  sht->col_inv = col_inv;
  return;
}

void sheet_updown(struct SHEET *sht, int height)
{
  struct SHTCTL *ctl = sht->ctl;
  int h, old = sht->height;	/* 設定前の高さを記憶する */

  /* 指定が低すぎや高すぎだったら、修正する */
  if (height > ctl->top + 1) {
    height = ctl->top + 1;
  }
  if (height < -1) {
    height = -1;
  }
  sht->height = height; 	/* 高さを設定 */

  /* 以下は主にsheet[]の並べ替え */
  if (old > height) {		/* 以前より低くなる */
    if (height >= 0) {
      /* 間のものを引き上げる */
      for (h = old; h > height; h--) {
	ctl->sheets[h] = ctl->sheets[h - 1];
	ctl->sheets[h]->height = h;
      }
      ctl->sheets[height] = sht;
    } else {			/* 非表示化 */
      if (ctl->top > old) {
	/* 上になっているものを下ろす */
	for (h = old; h < ctl->top; h++) {
	  ctl->sheets[h] = ctl->sheets[h + 1];
	  ctl->sheets[h]->height = h;
	}
      }
      ctl->top--;		/* 表示中の下敷きが1つ減るので一番上の高さが減る */
    }
    /* 新しい下敷きの情報に沿って画面を描き直す */
    sheet_refreshsub(ctl, sht->vx0, sht->vy0, sht->vx0 + sht->bxsize, sht->vy0 + sht->bxsize);		
  } else if (old < height) {	/* 以前より高くなる */
    if (old >= 0) {
      /* 間のものを押し下げる */
      for (h = old; h < height; h++) {
	ctl->sheets[h] = ctl->sheets[h + 1];
	ctl->sheets[h]->height = h;
      }
      ctl->sheets[height] = sht;
    } else {
      /* 上になるものを持ち上げる */
      for (h = ctl->top; h >= height; h--) {
	ctl->sheets[h + 1] = ctl->sheets[h];
	ctl->sheets[h + 1]->height = h + 1;
      }
      ctl->sheets[height] = sht;
      ctl->top++;		/* 表示中の下敷きが1つ増えるので、一番上の高さを変える */
    }
    /* 新しい下敷きの情報に沿って画面を描き直す */
    sheet_refreshsub(ctl, sht->vx0, sht->vy0, sht->vx0 + sht->bxsize, sht->vy0 + sht->bxsize);
  }
  return;
}

void sheet_refresh(struct SHEET *sht, int bx0, int by0, int bx1, int by1)
{
  if (sht->height >= 0) {
    sheet_refreshsub(sht->ctl, bx0, by0, bx1, by1);
  }
  return;
}

void sheet_refreshsub(struct SHTCTL *ctl, int vx0, int vy0, int vx1, int vy1)
{
  int h, bx, by, vx, vy, bx0, by0, bx1, by1;
  unsigned char *buf, c, *vram = ctl->vram;
  struct SHEET *sht;
  
  /* リフレッシュ範囲が画面外にはみ出していたら修正。 */
  if (vx0 < 0) { vx0 = 0; }
  if (vy0 < 0) { vy0 = 0; }
  if (vx1 > ctl->xsize) { vx1 = ctl->xsize; }
  if (vy1 > ctl->ysize) { vy1 = ctl->ysize; }
  
  for (h = 0; h <= ctl->top; h++) {
    sht = ctl->sheets[h];
    buf = sht->buf;
    /* vx0〜vy1を使ってbx0〜by1を逆算する */
    bx0 = vx0 - sht->vx0;
    by0 = vy0 - sht->vy0;
    bx1 = vx1 - sht->vx0;
    by1 = vy1 - sht->vy0;
    if (bx0 < 0) { bx0 = 0; }
    if (by0 < 0) { by0 = 0; }
    if (bx1 > sht->bxsize) { bx1 = sht->bxsize; }
    if (by1 > sht->bysize) { by1 = sht->bysize; }
    for (by = by0; by < by1; by++) {
      vy = sht->vy0 + by;
      for (bx = bx0; bx < bx1; bx++) {
	vx = sht->vx0 + bx;
	c = buf[by * sht->bxsize + bx];
	if (c != sht->col_inv) {
	  vram[vy * ctl->xsize + vx] = c;
	}
      }
    }
  }
  return;
}

void sheet_slide(struct SHEET *sht, int vx0, int vy0)
{
  int old_vx0 = sht->vx0, old_vy0 = sht->vy0;
  sht->vx0 = vx0;
  sht->vy0 = vy0;
  if (sht->height >= 0) {	/* もしも表示中なら、新しい下敷き情報に従って画面を描き直す */
    sheet_refreshsub(sht->ctl, old_vx0, old_vy0, old_vx0 + sht->bxsize, old_vy0 + sht->bysize);
    sheet_refreshsub(sht->ctl, vx0, vy0, vx0 + sht->bxsize, vy0 + sht->bysize);	
  }
  return;
}

void sheet_free(struct SHEET *sht)
{
  if (sht->height >= 0) {
    sheet_updown(sht, -1);	/* 表示中ならまず非表示にする */
  }

  sht->flags = 0;		/* 未使用マーク */
  return;
}
