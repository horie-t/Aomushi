.code32
	.global	io_halt

.text
io_halt:	# void io_halt(void) ;
	hlt
	ret
