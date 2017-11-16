	.equ	OS_ADDR, 0x102600
	
.arch i486

.text	
	movl	$1*8, %eax
	movw	%ax, %ds
	movb	$0, (OS_ADDR)
	movl	$4, %edx
	int	$0x40
