.code32
	.global	io_halt
	.global write_mem8

.text
io_halt:	# void io_halt(void) ;
	hlt
	ret

write_mem8:	# void write_mem8(int addr, int data) ;
	movl	4(%esp), %ecx	# %esp+4 にaddrが入っているので、ecxに
	movb	8(%esp), %al	# %esp+8 にdataが入っているので、alに
	movb	%al, (%ecx)
	ret
	
