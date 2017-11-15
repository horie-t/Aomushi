.arch i486

	movb 	$'A', %al
	lcall	$2*8, $0x0c2e
fin:
	hlt
	jmp fin
