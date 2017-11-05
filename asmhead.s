.file 	"aomushi.s"

	.equ	BOTPAK,	0x00280000	# bootbackのロード先
	.equ	DSKCAC,	0x00100000	# ディスク・キャッシュの場所
	.equ	DSKCAC0, 0x00008000	# ディスク・キャッシュの場所(リアル・モード)
	
	# BOOT_INFO関係
	.equ	CYLS, 	0x0ff0	# IPLが設定する。
	.equ	LEDS, 	0x0ff1	# Kyeboardの状態
	.equ	VMODE, 	0x0ff2	# 色数に関する情報。何ビット・カラーか
	.equ	SCRNX, 	0x0ff4	# 解像度のX(screen x)
	.equ	SCRNY, 	0x0ff6	# 解像度のY(screen y)
	.equ	VRAM, 	0x0ff8	# グラフィック・メモリの開始アドレス
	
.code16
.text

	# 画面モードの切り替え
	movb	$0x13, %al	# VGAグラフィックス、320 x 200 x 8bitカラー
	movb	$0x00, %ah
	int	$0x10
	
	# 画面モードをメモ
	movb	$8, (VMODE)
	movw	$320, (SCRNX)
	movw	$200, (SCRNY)
	movl	$0x000a0000, (VRAM)

	# キーボードのLED状態をBIOSに教えてもらう
	movb	$0x02, %ah
	int	$0x16		# keyboard BIOS
	movb	%al, (LEDS)

	# PIC(8259A)が一切の割り込みを受け付けないようにする。
	movb	$0xff, %al	# 全てのビットをマスクする。
	outb	%al, $0x21	# マスターPIC
	nop			# OUT命令を連続させると上手くいかない機種がある。
	outb	%al, $0xa1	# スレーブPIC

	cli			# CPUレベルでも割り込み禁止

	# CPUから1MB以上のメモリにアクセスできるように、A20GATEを設定
	call	waitkbdout
	movb	$0xd1, %al
	outb	%al, $0x64
	call	waitkbdout
	movb	$0xdf, %al	# A20ラインを有効にする
	outb	%al, $0x60
	call	waitkbdout

# プロテクトモード移行	
.arch i486
	lgdtl	(GDTR0)		# 暫定GDTを設定
	movl	%cr0, %eax
	andl	$0x7fffffff, %eax	# bit31を0にする(ページング禁止のため)
	orl	$0x00000001, %eax	# bit0を1にする(プロテクトモード移行のため)
	movl	%eax, %cr0
	jmp	pipelineflush

pipelineflush:
	movw	$1*8, %ax
	movw	%ax, %ds
	movw	%ax, %es
	movw	%ax, %fs
	movw	%ax, %gs
	movw	%ax, %ss

	# bootbackからの転送

	movl	$bootpack, %esi	# 転送元
	movl	$BOTPAK, %edi	# 転送先
	movl	$512*1024/4, %ecx	# 転送カウント(4byte単位でコピーするので4で割る)
	call	memcpy

	# ついでにディスク・データも本来の位置へ転送
	
	# まずは、ブート・セクタから
	movl	$0x7c00, %esi
	movl	$DSKCAC, %edi
	movl	$512/4, %ecx
	call	memcpy

	# 残り全部
	movl	$DSKCAC0+512, %esi
	movl	$DSKCAC+512, %edi
	movl	$0, %ecx
	movb	(CYLS), %cl
	imull	$512*18*2/4, %ecx	# シリンダ数からバイト数/4に変換
	subl	$512/4, %ecx		# IPLの分だけ差し引く
	call	memcpy

	# asmheadでしなければいけないことは、全部終わったので、
	# 後はbootbackに任せる

	# bootbackの起動
	movl	$BOTPAK, %ebx
	movl	16(%ebx), %ecx
	addl	$3, %ecx
	shrl	$2, %ecx
	jz	skip
	movl	20(%ebx), %esi
	addl	%ebx, %esi
	movl	12(%ebx), %edi
	call	memcpy

skip:
	movl	12(%ebx), %esp	# スタック初期値
	ljmpl	$2*8, $0x0000001b

waitkbdout:
	inb	$0x64, %al
	andb	$0x02, %al
	inb	$0x60, %al
	jnz	waitkbdout	# ANDの結果が0でなければwaitkbdoutへ
	ret

memcpy:	
	movl	(%esi), %eax
	addl	$4, %esi
	movl	%eax, (%edi)
	addl	$4, %edi
	subl 	$1, %ecx
	jnz	memcpy		# 引き算した結果が0でなければmemcpyへ
	ret

.align 8
GDT0:
	.skip	8, 0x00
	.word	0xffff, 0x0000, 0x9200, 0x00cf	# 読み書き可能セグメント32bit
	.word	0xffff, 0x0000, 0x9a28, 0x0047	# 実行可能セグメント32bit（bootpack用）
	
	.word	0x0000

GDTR0:
	.word	8*3-1
	.int	GDT0

.align 8
bootpack:
