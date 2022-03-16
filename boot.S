.section .text.boot

.global _start
_start:
	// Save the DTB pointer.
	mov	x29, x0

	// Set up a temporary stack.
	ldr     x5, =_start
	mov     sp, x5

	// Clear BSS.
	ldr	x5, =__bss_start
	ldr	w6, =__bss_size
	cbz	w6, 4f
1:	str	xzr, [x5], #8
	subs	w6, w6, #1
	b.ne	1b

	// Set up the stack pointer to use in EL1.
	mov	x0, sp
	msr	SP_EL1, x0

	// Switch to EL1 if we are running in EL2.
	mrs	x9, CurrentEL
	cmp	x9, 2 << 2
	b.ne	1f
	mov	x0, #(1<<9|1<<8|1<<7|1<<6|1<<2|1)
	msr	SPSR_EL2, x0
	ldr	x0, =1f
	msr	ELR_EL2, x0
	eret
1:

	// Set up TCR_EL1 (TG0[15:14] = 0, i.e. granule size 4K).
	mov	x0, 16            // T0SZ[0:5] = 16 -> use a 48 bit address space
	orr	x0, x0, 1 << 23   // EPD1[23] = 1 -> fault on TTBR1 translations
	msr	TCR_EL1, x0

	// Set up a temporary level 0 translation table.
	ldr	x0, =translation_table0
	ldr	x1, =translation_table1
	orr	x1, x1, #3       // Table descriptor, valid
	str	x1, [x0]         // Store entry
	msr	TTBR0_EL1, x0
	mov	x0, #0           // All memory set to device-nGnRnE
	msr	MAIR_EL1, x0

	// Enable MMU (with little-endian table walks).
	mrs	x0, SCTLR_EL1
	mov	x0, 1
	msr	SCTLR_EL1, x0
	isb

	// Some things in Zig's standard library use floating-point (e.g.
	// memcpy using q registers); make sure we don't trap these in EL1.
	mov	x0, #(0b11 << 20)
	msr	CPACR_EL1, x0

	ldr	x2, =4f

	mov	x0, x29
4:	bl	kernelMain

.global __delay
__delay:
1:	sub	w0, w0, #1
	cbnz	w0, 1b
	ret

.balign 4096
translation_table0:
	.rep 512
	.quad	0
	.endr

.balign 4096
translation_table1:
	// Four 1GB entries to cover the first 32 bits (4GB) of memory.
	.quad 0 << 30 | 1 << 10 | 1
	.quad 1 << 30 | 1 << 10 | 1
	.quad 2 << 30 | 1 << 10 | 1
	.quad 3 << 30 | 1 << 10 | 1
	.rep 508
	.quad 0
	.endr
