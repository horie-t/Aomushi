#include <stdarg.h>

#include "lib/aolib.h"
#include "bootpack.h"

#define EFLAGS_AC_BIT		0x00040000
#define CR0_CACHE_DISABLE	0x60000000

#define MEMMAN_FREES		4090 /* これで約32KB */

struct FREEINFO {		/* 空き情報 */
  unsigned int addr, size;
};

struct MEMMAN {			/* メモリ管理 */
  int frees, maxfrees, lostsize, losts;
  struct FREEINFO free[MEMMAN_FREES];
};

void memman_init(struct MEMMAN *man)
{
  man->frees = 0;	/* 空きの個数 */
  man->maxfrees = 0;	/* 状況観察用:freeの最大値 */
  man->lostsize = 0;	/* 解放に失敗した合計サイズ */
  man->losts = 0;	/* 解放に失敗した回数 */
  return;
};

/* 空きサイズの合計を報告 */
unsigned int memman_total(struct MEMMAN *man)
{
  unsigned int i, t = 0;
  for (i = 0; i < man->frees; i++) {
    t += man->free[i].size;
  }
  return t;
}

/* メモリを確保 */
unsigned int memman_alloc(struct MEMMAN *man, unsigned int size)
{
  unsigned int i, a;
  for (i = 0; i < man->frees; i++) {
    if (man->free[i].size >= size) {
      /* 十分な広さの空きを発見 */
      a = man->free[i].addr;
      man->free[i].addr += size;
      man->free[i].size -= size;
      if (man->free[i].size == 0) {
	/* free[i]がなくなったので前に詰める */
	man->frees--;
	for (; i < man->frees; i++) {
	  man->free[i] = man->free[i + 1];
	}
      }
      return a;
    }
  }
  return 0;			/* 空きがない */
}

/* メモリを解放 */
int memman_free(struct MEMMAN *man, unsigned int addr, unsigned int size)
{
  int i, j;
  /* まとめやすさを考えると、free[]がaddr順に並んでいる方がいい */
  /* まず、どこに入れるべきかを決める */
  for (i = 0; i < man->frees; i++) {
    if (man->free[i].addr > addr) {
      break;
    }
  }
  /* free[i - 1].addr < addr < free[i].addrになる */
  
  if (i > 0) {
    /* 前に空き領域ある */
    
    if (man->free[i - 1].addr + man->free[i -1].size == addr) {
      /* 前の空き領域にまとめられる */
      
      man->free[i - 1].size += size;
      if (i < man->frees) {
	/* 後ろにも空き領域がある */
	if (addr + size == man->free[i].addr) {
	  /* 後ろもまとめられる */
	  man->free[i - 1].size += man->free[i].size;
	  /* man->free[i]は不要。残りを前につめる */
	  man->frees--;
	  for (; i < man->frees; i++) {
	    man->free[i] = man->free[i + 1];
	  }
	}
      }
      return 0;			/* 成功終了 */
    }
  }

  /* 前とはまとめられなかった */
  if (i < man->frees) {
    /* 後ろに空き領域がある */
    if (addr + size == man->free[i].addr) {
      /* 後ろとまとめられる */
      man->free[i].addr = addr;
      man->free[i].size += size;
      return 0;	    /* 成功終了 */
    }
  }

  /* 前にも後ろにもまとめられなかった */
  if (man->frees < MEMMAN_FREES) {
    /* free[i]から後ろを、 後ろへずらして、free[i]を使えるようにする*/
    for (j = man->frees; j > i; j--) {
      man->free[j] = man->free[j - 1];
    }
    man->frees++;
    if (man->maxfrees < man->frees) {
      man->maxfrees = man->frees; /* 最大値を更新 */
    }
    man->free[i].addr = addr;
    man->free[i].size = size;
    return 0;			/* 成功終了 */
  }

  /* 後ろにずらせなかった */
  man->losts++;
  man->lostsize += size;
  return -1;			/* 失敗終了 */
}

int load_cr0();
void store_cr0(int cr0);
unsigned int memtest(unsigned int start, unsigned int end);
unsigned int memtest_sub(unsigned int start, unsigned int end);

extern struct FIFO8 keyfifo, mousefifo;

#define MEMMAN_ADDR	0x003c0000

void HariMain(void)
{
  struct BOOTINFO *binfo = (struct BOOTINFO *) ADR_BOOTINFO;
  char mcursor[16 * 16];
  char msg[256], s[16], keybuf[32], mousebuf[128];
  int mx, my;
  int i;
  
  struct MOUSE_DEC mdec;

  unsigned int memtotal;
  struct MEMMAN *memman = (struct MEMMAN *) MEMMAN_ADDR;

  init_gdtidt();
  init_pic();
  io_sti();	/* IDT/PICの初期化が完了したので、CPUの割り込み禁止を解除 */
  
  fifo8_init(&keyfifo, 32, keybuf);
  fifo8_init(&mousefifo, 128, mousebuf);
  io_out8(PIC0_IMR, 0xf9); /* PIC1とキーボードを許可(11111001) */
  io_out8(PIC1_IMR, 0xef); /* マウスを許可(11101111) */
  init_keyboard();
  
  init_pallete();
  init_screen(binfo->vram, binfo->scrnx, binfo->scrny);
  init_mouse_cursor8(mcursor, COL8_008484);

  /* マウス・カーソルを画面中心になるように計算し描画 */
  mx = (binfo->scrnx - 16) / 2;
  my = (binfo->scrny - 28 - 16) / 2;
  putblock8_8(binfo->vram, binfo->scrnx, 16, 16, mx, my, mcursor, 16);
  
  sprintk(msg, "(%d, %d)", mx, my);
  putfonts8_asc(binfo->vram, binfo->scrnx, 0, 0, COL8_FFFFFF, msg);

  enable_mouse(&mdec);

  memtotal = memtest(0x00400000, 0xbfffffff);
  memman_init(memman);
  memman_free(memman, 0x00001000, 0x0009e000);
  memman_free(memman, 0x00400000, memtotal - 0x00400000);
  sprintk(msg, "memory %dMB   free : %dKB",
	  memtotal / (1024 * 1024), memman_total(memman) / 1024);
  putfonts8_asc(binfo->vram, binfo->scrnx, 0, 32, COL8_FFFFFF, msg);
  
  for (;;) {
    io_cli();
    if (fifo8_status(&keyfifo) + fifo8_status(&mousefifo) == 0) {
      io_stihlt();
    } else {
      if (fifo8_status(&keyfifo) != 0) {
	i = fifo8_get(&keyfifo);
	io_sti();
      
	sprintk(s, "%02X", i);
	boxfill8(binfo->vram, binfo->scrnx, COL8_000000, 0, 16, 15, 31);
	putfonts8_asc(binfo->vram, binfo->scrnx, 0, 16, COL8_FFFFFF, s);
      } else if (fifo8_status(&mousefifo) != 0) {
	i = fifo8_get(&mousefifo);
	io_sti();

	if (mouse_decode(&mdec, i) != 0) {
	  /* データが3バイト揃ったので表示 */
	  sprintk(s, "[lcr %4d %4d]", mdec.buf[1], mdec.buf[2]);
	  if ((mdec.btn & 0x01) != 0) {
	    s[1] = 'L';
	  }
	  if ((mdec.btn & 0x02) != 0) {
	    s[3] = 'R';
	  }
	  if ((mdec.btn & 0x04) != 0) {
	    s[2] = 'C';
	  }
	  boxfill8(binfo->vram, binfo->scrnx, COL8_000000, 32, 16, 32 + 15 * 8 - 1, 31);
	  putfonts8_asc(binfo->vram, binfo->scrnx, 32, 16, COL8_FFFFFF, s);

	  /* マウス・カーソルの移動 */
	  boxfill8(binfo->vram, binfo->scrnx, COL8_008484, mx, my, mx + 15, my + 15); /* マウスを消す */
	  mx += mdec.x;
	  my += mdec.y;
	  if (mx < 0) {
	    mx = 0;
	  }
	  if (my < 0) {
	    my = 0;
	  }
	  if (mx > binfo->scrnx - 16) {
	    mx = binfo->scrnx - 16;
	  }
	  if (my > binfo->scrny - 16) {
	    my = binfo->scrny - 16;
	  }
	  sprintk(msg, "(%3d, %3d)", mx, my);
	  boxfill8(binfo->vram, binfo->scrnx, COL8_008484, 0, 0, 79, 15);	/* 座標を消す */
	  putfonts8_asc(binfo->vram, binfo->scrnx, 0, 0, COL8_FFFFFF, msg);	/* 座標を書く */
	  putblock8_8(binfo->vram, binfo->scrnx, 16, 16, mx, my, mcursor, 16);	/* マウスを描く */
	}
      }
    }
  }
}

unsigned int memtest(unsigned int start, unsigned int end)
{
  char flg486;
  unsigned int eflg, cr0, i;

  /* 386か、486以降なのかを確認 */
  eflg = io_load_eflags();
  eflg |= EFLAGS_AC_BIT;	/* AC-bit = 1 */
  io_store_eflags(eflg);

  eflg = io_load_eflags();
  if ((eflg & EFLAGS_AC_BIT) != 0) {
    /* 386だとAC=1にしても0に戻ってしまうので、ここには来ない */
    flg486 = 1;
  }
  eflg &= ~EFLAGS_AC_BIT;	/* AC-bit = 0 */
  io_store_eflags(eflg);

  if (flg486 != 0) {
    cr0 = load_cr0();
    cr0 |= CR0_CACHE_DISABLE;	/* キャッシュ禁止 */
    store_cr0(cr0);
  }

  i = memtest_sub(start, end);

  if (flg486 != 0) {
    cr0 = load_cr0();
    cr0 &= ~CR0_CACHE_DISABLE;	/* キャッシュ許可 */
    store_cr0(cr0);
  }

  return i;
}
