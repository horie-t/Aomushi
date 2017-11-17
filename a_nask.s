.file "a_nask.s"
.arch i486

	.global api_end
	
	.global api_putchar
	.global api_putstr0

	.global api_openwin
	.global api_putstrwin
	.global api_boxfilwin

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
	
