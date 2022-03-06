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

.global __delay
__delay:
1:	sub	w0, w0, #1
	cbnz	w0, 1b
	ret
