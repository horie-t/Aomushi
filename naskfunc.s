
	.equ	CONSOLE, 0x0fec		# コンソール構造体のアドレス
	.equ	OS_ESP, 0xfe4		# OS用のESP
	
.code32
	.extern inthandler21, inthandler21, inthander27, inthandler2c
	.extern cons_putchar
	.extern hrb_api
	
	.global	io_hlt, io_cli, io_sti, io_stihlt
	
	.global io_in8, io_in16, io_in32
	.global io_out8, io_out16, io_out32
	
	.global io_load_eflags, io_store_eflags
	.global load_gdtr, load_idtr
	.global load_cr0, store_cr0
	.global load_tr

	.global asm_inthandler0d
	.global asm_inthandler20, asm_inthandler21, asm_inthandler27, asm_inthandler2c
	.global asm_cons_putchar
	.global asm_hrb_api
	.global start_app

	.global memtest_sub

	.global farjmp
	.global farcall
	
.text
io_hlt:		# void io_hlt(void)
	hlt
	ret

io_cli:		# void io_cli(void)
	cli
	ret

io_sti:		# void io_sti(void)
	sti
	ret

io_stihlt:	# void io_stihlt(void)
	sti
	hlt
	ret

io_in8:		# int io_in8(int port)
	movl	4(%esp), %edx
	movl	$0, %eax
	inb	%dx, %al
	ret

io_in16:	# int io_in16(int port)
	movl	4(%esp), %edx
	movl	$0, %eax
	inw	%dx, %ax
	ret

io_in32:	# int io_in32(int port)
	movl	4(%esp), %edx
	movl	$0, %eax
	inl	%dx, %eax
	ret
	
io_out8:	# int io_out8(int port, int data)
	movl	4(%esp), %edx
	movb	8(%esp), %al
	outb	%al, %dx
	ret
	
io_out16:	# int io_out16(int port, int data)
	movl	4(%esp), %edx
	movl	8(%esp), %eax
	outw	%ax, %dx
	ret
	
io_out32:	# int io_out32(int port, int data)
	movl	4(%esp), %edx
	movl	8(%esp), %eax
	outl	%eax, %dx
	ret

io_load_eflags:	# int io_load_eflags(void)
	pushf			# push eflags
	pop 	%eax
	ret

io_store_eflags:	# void io_store_eflags(int eflags)
	movl	4(%esp), %eax
	push	%eax
	popf			# pop eflags
	ret

load_gdtr:	# void load_gdtr(int limit, int addr)
	movw	4(%esp), %ax	# limit
	movw	%ax, 6(%esp)
	lgdt	6(%esp)
	ret

load_idtr:	# void load_idtr(int limit, int addr)
	movw	4(%esp), %ax	# limit
	movw	%ax, 6(%esp)
	lidt	6(%esp)
	ret

load_cr0:	# int load_cr0()
	movl	%cr0, %eax
	ret

store_cr0:	# void store_cr0(int cr0)
	movl	4(%esp), %eax
	movl	%eax, %cr0
	ret

load_tr:	# void load_tr(int tr)
	ltr	4(%esp)
	ret

asm_inthandler0d:
	sti
	pushw 	%es
	pushw	%ds
	pusha
	movw	%ss, %ax
	cmpw	$1*8, %ax
	jne	1f
	
	movl	%esp, %eax
	push	%ss
	pushl	%eax
	movw	%ss, %ax
	movw	%ax, %ds
	movw	%ax, %es
	call	inthandler0d
	addl	$8, %esp	
	popa
	popw	%ds
	popw	%es
	iret
1:	# アプリが動いている時に割り込まれた
	cli
	movl	$1*8, %eax
	movw	%ax, %ds	# とりあえずDSだけOS用にする
	movl	(OS_ESP), %ecx	# OSのESP
	addl	$-8, %ecx
	movw	%ss, 4(%ecx)	# 割り込まれた時のSSを保存
	movl	%esp, (%ecx)	# 割り込まれた時のESPを保存
	movw	%ax, %ss
	movw	%ax, %es
	movl	%esp, %ecx
	sti
	call	inthandler20
	cli
	cmpl	$0, %eax
	jne	2f
	popl	%ecx
	popl	%eax
	movw	%ax, %ss
	movl	%ecx, %esp
	popa
	popw	%ds
	popw	%es
	iret
2:	# アプリを異常終了させる事にした
	movl	$1*8, %eax
	movw	%ax, %es
	movw	%ax, %ss
	movw	%ax, %ds
	movw	%ax, %fs
	movw	%ax, %gs
	movl	(OS_ESP), %esp	# start_appの時のESPに無理矢理戻す
	sti			# 割り込み可能に戻す
	popa
	ret
	
asm_inthandler20:
	pushw 	%es
	pushw	%ds
	pusha
	movw	%ss, %ax
	cmpw	$1*8, %ax
	jne	1f
	
	movl	%esp, %eax
	push	%ss
	pushl	%eax
	movw	%ss, %ax
	movw	%ax, %ds
	movw	%ax, %es
	call	inthandler20
	addl	$8, %esp	
	popa
	popw	%ds
	popw	%es
	iret
1:	# アプリが動いている時に割り込まれた
	movl	$1*8, %eax
	movw	%ax, %ds	# とりあえずDSだけOS用にする
	movl	(OS_ESP), %ecx	# OSのESP
	addl	$-8, %ecx
	movw	%ss, 4(%ecx)	# 割り込まれた時のSSを保存
	movl	%esp, (%ecx)	# 割り込まれた時のESPを保存
	movw	%ax, %ss
	movw	%ax, %es
	movl	%esp, %ecx
	call	inthandler20
	popl	%ecx
	popl	%eax
	movw	%ss, %ax
	movl	%esp, %ecx
	popa
	popw	%ds
	popw	%es
	iret

asm_inthandler21:
	pushw 	%es
	pushw	%ds
	pusha
	movw	%ss, %ax
	cmpw	$1*8, %ax
	jne	1f
	
	movl	%esp, %eax
	push	%ss
	pushl	%eax
	movw	%ss, %ax
	movw	%ax, %ds
	movw	%ax, %es
	call	inthandler21
	addl	$8, %esp	
	popa
	popw	%ds
	popw	%es
	iret
1:	# アプリが動いている時に割り込まれた
	movl	$1*8, %eax
	movw	%ax, %ds	# とりあえずDSだけOS用にする
	movl	(OS_ESP), %ecx	# OSのESP
	addl	$-8, %ecx
	movw	%ss, 4(%ecx)	# 割り込まれた時のSSを保存
	movl	%esp, (%ecx)	# 割り込まれた時のESPを保存
	movw	%ax, %ss
	movw	%ax, %es
	movl	%esp, %ecx
	call	inthandler21
	popl	%ecx
	popl	%eax
	movw	%ss, %ax
	movl	%esp, %ecx
	popa
	popw	%ds
	popw	%es
	iret
	
asm_inthandler27:
	pushw 	%es
	pushw	%ds
	pusha
	movw	%ss, %ax
	cmpw	$1*8, %ax
	jne	1f
	
	movl	%esp, %eax
	push	%ss
	pushl	%eax
	movw	%ss, %ax
	movw	%ax, %ds
	movw	%ax, %es
	call	inthandler27
	addl	$8, %esp	
	popa
	popw	%ds
	popw	%es
	iret
1:	# アプリが動いている時に割り込まれた
	movl	$1*8, %eax
	movw	%ax, %ds	# とりあえずDSだけOS用にする
	movl	(OS_ESP), %ecx	# OSのESP
	addl	$-8, %ecx
	movw	%ss, 4(%ecx)	# 割り込まれた時のSSを保存
	movl	%esp, (%ecx)	# 割り込まれた時のESPを保存
	movw	%ax, %ss
	movw	%ax, %es
	movl	%esp, %ecx
	call	inthandler27
	popl	%ecx
	popl	%eax
	movw	%ss, %ax
	movl	%esp, %ecx
	popa
	popw	%ds
	popw	%es
	iret

asm_inthandler2c:
	pushw 	%es
	pushw	%ds
	pusha
	movw	%ss, %ax
	cmpw	$1*8, %ax
	jne	1f
	
	movl	%esp, %eax
	push	%ss
	pushl	%eax
	movw	%ss, %ax
	movw	%ax, %ds
	movw	%ax, %es
	call	inthandler2c
	addl	$8, %esp	
	popa
	popw	%ds
	popw	%es
	iret
1:	# アプリが動いている時に割り込まれた
	movl	$1*8, %eax
	movw	%ax, %ds	# とりあえずDSだけOS用にする
	movl	(OS_ESP), %ecx	# OSのESP
	addl	$-8, %ecx
	movw	%ss, 4(%ecx)	# 割り込まれた時のSSを保存
	movl	%esp, (%ecx)	# 割り込まれた時のESPを保存
	movw	%ax, %ss
	movw	%ax, %es
	movl	%esp, %ecx
	call	inthandler2c
	popl	%ecx
	popl	%eax
	movw	%ss, %ax
	movl	%esp, %ecx
	popa
	popw	%ds
	popw	%es
	iret
	
asm_cons_putchar:
	sti
	push	$1
	andl	$0xff, %eax
	pushl	%eax
	pushl	(CONSOLE)
	call	cons_putchar
	addl	$12, %esp
	iret

asm_hrb_api:
	# 最初から割り込み禁止になっている
	pushw	%ds
	pushw	%es
	pusha			# 保存のためpush
	movl	$1*8, %eax
	movw	%ax, %ds	# とりあえずDSだけOS用にする
	movl	(OS_ESP), %ecx	# OS用のEIP
	addl	$-40, %ecx
	movl	%esp, 32(%ecx)	# アプリのESPを保存
	movw	%ss, 36(%ecx)	# アプリのSSを保存

	# pushaした値をシステムのスタックにコピーする
	movl	(%esp), %edx
	movl	4(%esp), %ebx
	movl	%edx, (%ecx) 	# hrb_apiに渡すためコピー
	movl	%ebx, 4(%ecx) 	# hrb_apiに渡すためコピー
	movl	8(%esp), %edx
	movl	12(%esp), %ebx
	movl	%edx, 8(%ecx)	# hrb_apiに渡すためコピー
	movl	%ebx, 12(%ecx)	# hrb_apiに渡すためコピー
	movl	16(%esp), %edx
	movl	20(%esp), %ebx
	movl	%edx, 16(%ecx)	# hrb_apiに渡すためコピー
	movl	%ebx, 20(%ecx)	# hrb_apiに渡すためコピー
	movl	24(%esp), %edx
	movl	28(%esp), %ebx
	movl	%edx, 24(%ecx)	# hrb_apiに渡すためコピー
	movl	%ebx, 28(%ecx)	# hrb_apiに渡すためコピー

	movw	%ax, %es	# 残りのセグメントレジスタもOS用にする
	movw	%ax, %ss
	movl	%ecx, %esp
	sti			# やっと割り込み許可

	call	hrb_api

	movl	32(%esp), %ecx	# アプリのESPを思い出す
	movl	36(%esp), %eax	# アプリのSSを思い出す
	cli
	movw	%ax, %ss
	movl	%ecx, %esp
	popa
	popw	%es
	popw	%ds
	iret

start_app:	# void start_app(int eip, int cs, int esp, int ds)
	pusha			# 32ビット・レジスタを全部保存しておく
	movl	36(%esp), %eax	# アプリ用のEIP
	movl	40(%esp), %ecx	# アプリ用のCS
	movl	44(%esp), %edx	# アプリ用のESP
	movl	48(%esp), %ebx	# アプリ用のDS/SS
	movl	%esp, (OS_ESP)	# OS用のESP
	cli			# 切り替え中に割り込みが来て欲しくないので、禁止
	movw	%bx, %es
	movw	%bx, %ss
	movw	%bx, %ds
	movw	%bx, %fs
	movw	%bx, %gs
	movl	%edx, %esp
	sti			# 切り替え完了なので、割り込み可能に戻す
	pushl	%ecx		# far-callのためpush(cs)
	pushl	%eax		# far-callのためpush(eip)
	lcall	*(%esp)		# アプリを呼び出す
	# アプリが終了するとここに帰ってくる
	movl 	$1*8, %eax	# OS用のDS/SS
	cli			# また切り替えるので、割り込み禁止
	movw	%ax, %es
	movw	%ax, %ss
	movw	%ax, %ds
	movw	%ax, %fs
	movw	%ax, %gs
	movl	(OS_ESP), %esp
	sti			# 切り替え完了なので、割り込み可能に戻す
	popa
	ret
	
memtest_sub:	# unsigned int memtest_sub(unsigned int start, unsigned int end)
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	movl	$0xaa55aa55, %esi	# pat0 = 0xaa55aa55
	movl	$0x55aa55aa, %edi	# pat1 = 0x55aa55aa
	movl	16(%esp), %eax		# i = start
mts_loop:
	movl	%eax, %ebx
	addl	$0xffc, %ebx		# p = i + 0xffc
	movl	(%ebx), %edx		# old = *p
	movl	%esi, (%ebx)		# *p = pat0
	xorl	$0xffffffff, (%ebx)	# *p ^= 0xffffffff
	cmpl	(%ebx), %edi		# if (*p != pat1) goto mts_fin
	jne	mts_fin
	xorl	$0xffffffff, (%ebx)	# *p ^= 0xffffffff
	cmpl	(%ebx), %esi		# if (*p != pat0) goto mts_fin
	jne	mts_fin
	movl	%edx, (%ebx)		# *p = old
	addl	$0x1000, %eax 		# i += 0x1000
	cmpl	20(%esp), %eax 		# if (i <= end) goto mts_loop
	jbe	mts_loop
	popl	%ebx
	popl	%esi
	popl	%edi
	ret
mts_fin:
	movl	%edx, (%ebx)		# *p = old
	popl	%ebx
	popl	%esi
	popl	%edi
	ret

farjmp:		# void farjmp(int eip, int cs)
	ljmpl	*4(%esp)
	ret

farcall:	# void farcall(int eip, int cs)
	lcall	*4(%esp)
	ret

