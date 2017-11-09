.code32
	.extern inthandler21, inthandler21, inthander27, inthandler2c
	
	.global	io_hlt, io_cli, io_sti, io_stihlt
	
	.global io_in8, io_in16, io_in32
	.global io_out8, io_out16, io_out32
	
	.global io_load_eflags, io_store_eflags
	.global load_gdtr, load_idtr
	.global load_cr0, store_cr0

	.global asm_inthandler20, asm_inthandler21, asm_inthandler27, asm_inthandler2c

	.global memtest_sub
	
.text
io_hlt:		# void io_hlt(void)
	hlt
	ret

io_cli:		# void io_cli(void)
	cli
	ret

io_sti:		# void io_sti(void)
	sti
	ret

io_stihlt:	# void io_stihlt(void)
	sti
	hlt
	ret

io_in8:		# int io_in8(int port)
	movl	4(%esp), %edx
	movl	$0, %eax
	inb	%dx, %al
	ret

io_in16:	# int io_in16(int port)
	movl	4(%esp), %edx
	movl	$0, %eax
	inw	%dx, %ax
	ret

io_in32:	# int io_in32(int port)
	movl	4(%esp), %edx
	movl	$0, %eax
	inl	%dx, %eax
	ret
	
io_out8:	# int io_out8(int port, int data)
	movl	4(%esp), %edx
	movb	8(%esp), %al
	outb	%al, %dx
	ret
	
io_out16:	# int io_out16(int port, int data)
	movl	4(%esp), %edx
	movl	8(%esp), %eax
	outw	%ax, %dx
	ret
	
io_out32:	# int io_out32(int port, int data)
	movl	4(%esp), %edx
	movl	8(%esp), %eax
	outl	%eax, %dx
	ret

io_load_eflags:	# int io_load_eflags(void)
	pushf			# push eflags
	pop 	%eax
	ret

io_store_eflags:	# void io_store_eflags(int eflags)
	movl	4(%esp), %eax
	push	%eax
	popf			# pop eflags
	ret

load_gdtr:	# void load_gdtr(int limit, int addr)
	movw	4(%esp), %ax	# limit
	movw	%ax, 6(%esp)
	lgdt	6(%esp)
	ret

load_idtr:	# void load_idtr(int limit, int addr)
	movw	4(%esp), %ax	# limit
	movw	%ax, 6(%esp)
	lidt	6(%esp)
	ret

load_cr0:	# int load_cr0()
	movl	%cr0, %eax
	ret

store_cr0:	# void store_cr0(int cr0)
	movl	4(%esp), %eax
	movl	%eax, %cr0
	ret

asm_inthandler20:
	pushw 	%es
	pushw	%ds
	pusha
	movl	%esp, %eax
	push	%eax
	movw	%ss, %ax
	movw	%ax, %ds
	movw	%ax, %es
	call	inthandler20
	popl	%eax
	popa
	popw	%ds
	popw	%es
	iret
	
asm_inthandler21:
	pushw 	%es
	pushw	%ds
	pusha
	movl	%esp, %eax
	pushl	%eax
	movw	%ss, %ax
	movw	%ax, %ds
	movw	%ax, %es
	call	inthandler21
	popl 	%eax
	popa
	popw	%ds
	popw	%es
	iret

asm_inthandler27:
	pushw 	%es
	pushw	%ds
	pusha
	movl	%esp, %eax
	pushl	%eax
	movw	%ss, %ax
	movw	%ax, %ds
	movw	%ax, %es
	call	inthandler27
	popl 	%eax
	popa
	popw	%ds
	popw	%es
	iret

asm_inthandler2c:
	pushw 	%es
	pushw	%ds
	pusha
	movl	%esp, %eax
	pushl	%eax
	movw	%ss, %ax
	movw	%ax, %ds
	movw	%ax, %es
	call	inthandler2c
	popl 	%eax
	popa
	popw	%ds
	popw	%es
	iret

memtest_sub:	# unsigned int memtest_sub(unsigned int start, unsigned int end)
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	movl	$0xaa55aa55, %esi	# pat0 = 0xaa55aa55
	movl	$0x55aa55aa, %edi	# pat1 = 0x55aa55aa
	movl	16(%esp), %eax		# i = start
mts_loop:
	movl	%eax, %ebx
	addl	$0xffc, %ebx		# p = i + 0xffc
	movl	(%ebx), %edx		# old = *p
	movl	%esi, (%ebx)		# *p = pat0
	xorl	$0xffffffff, (%ebx)	# *p ^= 0xffffffff
	cmpl	(%ebx), %edi		# if (*p != pat1) goto mts_fin
	jne	mts_fin
	xorl	$0xffffffff, (%ebx)	# *p ^= 0xffffffff
	cmpl	(%ebx), %esi		# if (*p != pat0) goto mts_fin
	jne	mts_fin
	movl	%edx, (%ebx)		# *p = old
	addl	$0x1000, %eax 		# i += 0x1000
	cmpl	20(%esp), %eax 		# if (i <= end) goto mts_loop
	jbe	mts_loop
	popl	%ebx
	popl	%esi
	popl	%edi
	ret
mts_fin:
	movl	%edx, (%ebx)		# *p = old
	popl	%ebx
	popl	%esi
	popl	%edi
	ret
	
