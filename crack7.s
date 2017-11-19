.file	"crack7.s"
.arch 	i486

	.global	HariMain

	.equ	HARI_SIG_ADDR,	0x0004
	.equ	BASE, 0x0000
.text	
HariMain:
	movw	$1005*8, %ax
	movw	%ax, %ds
	cmpl	$0x69726148, %ds:(HARI_SIG_ADDR)	# 0x69726148は'Hari'
	jne	fin

	movl	%ds:(BASE), %ecx
	movw	$2005*8, %ax
	movw	%ax, %ds

crackloop:
	addl	$-1, %ecx
	movb	$123, %ds:(%ecx)
	cmpl	$0, %ecx
	jne	crackloop

fin:
	movl	$4, %edx
	int	$0x40
