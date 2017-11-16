.arch i486
.text

	movl	$2, %edx
	movl	$msg, %ebx
	int	$0x40
	movl	$4, %edx
	int	$0x40
msg:
	.string	"hello"
	
