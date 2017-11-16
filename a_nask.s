.file "a_nask.s"
.arch i486

	.global api_putchar
	.global api_end

.text
api_putchar:	# void api_putchar(int c)
	movl	$1, %edx
	movb	4(%esp), %al
	int	$0x40
	ret

api_end:	# void api_end(void)
	movl	$4, %edx
	int	$0x40

	
