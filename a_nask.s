.file "a_nask.s"
.arch i486

	.global api_end
	
	.global api_putchar
	.global api_putstr0

	.global api_openwin

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
