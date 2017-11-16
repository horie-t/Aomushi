.arch i486
.text
	
	movl	$msg, %ecx
	movl	$1, %edx
putloop:
	movb	%cs:(%ecx), %al
	cmpb	$0, %al
	je	fin
	int	$0x40
	addl	$1, %ecx
	jmp	putloop
fin:
	movl	$4, %edx
	int	$0x40
msg:
	.string	"hello"
