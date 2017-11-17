.file "a_nask.s"
.arch i486

	.global api_putchar
	.global api_end
	.global api_putstr0

.text
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
	
api_end:	# void api_end(void)
	movl	$4, %edx
	int	$0x40

	
