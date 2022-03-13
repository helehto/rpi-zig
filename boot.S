.section .text.boot

.global _start
_start:
	// Set up a temporary stack.
	ldr     x5, =_start
	mov     sp, x5

	// Clear BSS.
	ldr	x5, =__bss_start
	ldr	w6, =__bss_size
	cbz	w6, 4f
3:	str	xzr, [x5], #8
	subs	w6, w6, #1
	b.ne	3b

4:	bl	kernelMain

.global __switch_to_el1
__switch_to_el1:
	msr	SPSR_EL2, x0

	// Jump to .__switch_to_el1_dest with EL1 on eret.
	ldr	x0, =.__switch_to_el1_dest
	msr	ELR_EL2, x0

	// Re-use the current stack pointer.
	mov	x0, sp
	msr	SP_EL1, x0

	eret
.__switch_to_el1_dest:
	ret

.global __change_el1
__change_el1:
	msr	SPSR_EL1, x0

	// Jump to .__change_el1_dest with EL1 on eret.
	ldr	x0, =.__change_el1_dest
	msr	ELR_EL1, x0

	eret
.__change_el1_dest:
	ret

.global __delay
__delay:
1:	sub	w0, w0, #1
	cbnz	w0, 1b
	ret
