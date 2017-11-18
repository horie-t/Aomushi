.file "a_nask.s"

	.equ	MALLOC_ADDR, 0x0020	# .hrbヘッダのmalloc領域
	.equ	DS_SIZE, 0x0000		# .hrbヘッダのデータセグメントのサイズ
	
.arch i486

	.global api_end
	
	.global api_putchar
	.global api_putstr0

	.global api_openwin, api_closewin
	.global api_refreshwin
	.global api_putstrwin
	.global api_boxfilwin
	.global	api_point
	.global api_linewin
	.global api_getkey
	.global api_alloctimer, api_inittimer, api_settimer, api_freetimer

	.global api_initmalloc, api_malloc, api_free

.text
api_end:	# void api_end(void)
	movl	$4, %edx
	int	$0x40

api_putchar:	# void api_putchar(int c)
	movl	$1, %edx
	movb	4(%esp), %al
	int	$0x40
	ret

api_putstr0:	# void api_putstr0(char *s)
	pushl	%ebx
	movl	$2, %edx
	movl	8(%esp), %ebx	# s
	int	$0x40
	popl	%ebx
	ret
	
api_openwin:	# int api_openwin(char *buf, int xsiz, int ysiz, int col_inv, char *title)
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	movl	$5, %edx
	movl	16(%esp), %ebx	# buf
	movl	20(%esp), %esi	# xsiz
	movl	24(%esp), %edi	# ysiz
	movl	28(%esp), %eax	# col_inv
	movl	32(%esp), %ecx	# title
	int	$0x40
	popl	%ebx
	popl	%esi
	popl	%edi
	ret

api_closewin:	# void api_closewin(int win)
	pushl	%ebx
	movl	$14, %edx
	movl	8(%esp), %ebx	# win
	int 	$0x40
	popl	%ebx
	ret
	
api_refreshwin:	# void api_refreshwin(int win, int x0, int y0, int x1, int y1)
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	movl	$12, %edx
	movl	16(%esp), %ebx	# win
	movl	20(%esp), %eax	# x0
	movl	24(%esp), %ecx	# y0
	movl	28(%esp), %esi	# x1
	movl	32(%esp), %edi	# y1
	int 	$0x40
	popl 	%ebx
	popl	%esi
	popl	%edi
	ret
	
api_putstrwin:	# void api_putstrwin(int win, int x, int y, int col, int len, char *str)
	pushl	%edi
	pushl	%esi
	pushl	%ebp
	pushl	%ebx
	movl	$6, %edx
	movl	20(%esp), %ebx	# win
	movl	24(%esp), %esi	# x
	movl	28(%esp), %edi	# y
	movl	32(%esp), %eax	# col
	movl	36(%esp), %ecx	# len
	movl	40(%esp), %ebp	# str
	int 	$0x40
	popl 	%ebx
	popl	%ebp
	popl	%esi
	popl	%edi
	ret

api_boxfilwin:	# void api_boxfilwin(int win, int x0, int y0, int x1, int y1, int col)
	pushl	%edi
	pushl	%esi
	pushl	%ebp
	pushl	%ebx
	movl	$7, %edx
	movl	20(%esp), %ebx	# win
	movl	24(%esp), %eax	# x0
	movl	28(%esp), %ecx	# y0
	movl	32(%esp), %esi	# x1
	movl	36(%esp), %edi	# y1
	movl	40(%esp), %ebp	# col
	int 	$0x40
	popl 	%ebx
	popl	%ebp
	popl	%esi
	popl	%edi
	ret

api_point:	# void api_point(int win, int x, int y, int col)
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	movl	$11, %edx
	movl	16(%esp), %ebx	# win
	movl	20(%esp), %esi	# x
	movl	24(%esp), %edi	# y
	movl	28(%esp), %eax	# col
	int	$0x40
	popl	%ebx
	popl	%esi
	popl	%edi
	ret

api_linewin:	# void api_linewin(int win, int x0, int y0, int x1, int y1, int col)
	pushl	%edi
	pushl	%esi
	pushl	%ebp
	pushl	%ebx
	movl	$13, %edx
	movl	20(%esp), %ebx	# win
	movl	24(%esp), %eax	# x0
	movl	28(%esp), %ecx	# y0
	movl	32(%esp), %esi	# x1
	movl	36(%esp), %edi	# y1
	movl	40(%esp), %ebp	# col
	int 	$0x40
	popl 	%ebx
	popl	%ebp
	popl	%esi
	popl	%edi
	ret

api_getkey:	# int api_getkey(int mode)
	movl	$15, %edx
	movl	4(%esp), %eax	# mode
	int 	$0x40
	ret

api_alloctimer:	# int api_alloctimer(void)
	movl	$16, %edx
	int 	$0x40
	ret

api_inittimer:	# void api_inittimer(int timer, int data)
	pushl	%ebx
	movl	$17, %edx
	movl	8(%esp), %ebx	# timer
	movl	12(%esp), %eax	# data
	int	$0x40
	popl	%ebx
	ret

api_settimer:	# void api_settimer(int timer, int time)
	pushl	%ebx
	movl	$18, %edx
	movl	8(%esp), %ebx	# timer
	movl	12(%esp), %eax	# time
	int 	$0x40
	popl	%ebx
	ret

api_freetimer:	# void api_freetimer(int timer)
	pushl	%ebx
	movl	$19, %edx
	movl	8(%esp), %ebx	# timer
	int	$0x40
	popl	%ebx
	ret
	
api_initmalloc:	# void api_initmalloc(void)
	pushl	%ebx
	movl	$8, %edx
	movl	%cs:(MALLOC_ADDR), %ebx
	movl	%ebx, %eax
	addl	$32*1024, %eax
	movl	%cs:(DS_SIZE), %ecx
	subl	%eax, %ecx
	int	$0x40
	popl	%ebx
	ret

api_malloc:	# char *api_malloc(int size)
	pushl	%ebx
	movl	$9, %edx
	movl	%cs:(MALLOC_ADDR), %ebx
	movl	8(%esp), %ecx	# size
	int	$0x40
	popl	%ebx
	ret

api_free:	# void api_free(char *addr, int size)
	pushl	%ebx
	movl	$10, %edx
	movl	%cs:(MALLOC_ADDR), %ebx
	movl	8(%esp), %eax	# addr
	movl	12(%esp), %ecx	# size
	int 	$0x40
	popl	%ebx
	ret

