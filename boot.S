//
// Memory map after this boot code has run:
//
// Identity mapping: (4GB)
// Virt 0x0000000000000000-0x0000000100000000
// Phys 0x0000000000000000-0x0000000100000000
//   L0[0] -> L1[0:3]
//
// Kernel image: (8MB)
// Virt 0x0000f00000000000-0x0000f00000800000
// Phys 0x0000000000200000-0x0000000000a00000
//   L0[480] -> L1[0] -> L2[0:7]
//
// Mapped physical memory: (512 GB)
// Virt 0x0000ff0000000000-0x0000ff8000000000
// Phys 0x0000000000000000-0x0000008000000000
//   L0[510] -> L1[0:511]
//

.section .bootstrap, "ax"

.type _start, function
.global _start
_start:
	// Save the DTB pointer.
	mov	x29, x0

	// Set up a temporary stack.
	ldr     x5, =_start
	mov     sp, x5

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

	ldr	x0, =translation_table0
	msr	TTBR0_EL1, x0

	// All memory set to device-nGnRnE for now.
	mov	x3, #0
	msr	MAIR_EL1, x3

	// Set up identity memory mapping (see memory map above).
	ldr	x1, =tt1_identity_map
	orr	x2, x1, #3       // Table descriptor, valid
	str	x2, [x0]         // Store entry

	// Set up kernel image memory mapping (see memory map above).
	add	x2, x0, #(8 * 480)
	ldr	x1, =tt1_kernel_image
	orr	x3, x1, #3       // Table descriptor, valid
	str	x3, [x2]         // Store entry
	ldr	x4, =tt2_kernel_image
	orr	x5, x4, #3       // Table descriptor, valid
	str	x5, [x1]

	// Set up physical memory mapping (see memory map above).
	add	x2, x0, #(8 * 510)
	ldr	x1, =tt1_physical_map
	orr	x3, x1, #3       // Table descriptor, valid
	str	x3, [x2]         // Store entry

	// Move kernel to 2MB to align with the level 2 page tables.
	ldr	x1, =__kernel_phys_end
	ldr	x2, =__kernel_size
	add	x3, x2, #(1 << 21)
2:	ldp	x4, x5, [x1, #-16]!
	stp	x4, x5, [x3, #-16]!
	sub	x2, x2, #16
	cbnz	x2, 2b

	// Enable MMU (with little-endian table walks).
	mrs	x0, SCTLR_EL1
	mov	x0, 1
	msr	SCTLR_EL1, x0
	isb

	// Jump to higher address space.
	mov	x0, x29
	ldr	x1, =_start_hi
	br	x1
.size _start, .-_start

// Dump the constant pool here. We need a ton of padding for the translation
// table anyway, and having the assembler dump them at the end of the
// .bootstrap section throws off the alignment of the .text section in the raw
// binary.
.ltorg

.balign 4096
translation_table0:
	.rep 512
		.quad	0
	.endr

.balign 4096
tt1_identity_map:
	.quad 0 << 30 | 1 << 10 | 1
	.quad 1 << 30 | 1 << 10 | 1
	.quad 2 << 30 | 1 << 10 | 1
	.quad 3 << 30 | 1 << 10 | 1
	.rep 508
		.quad 0
	.endr

.balign 4096
tt1_kernel_image:
	.rep 512
		.quad 0
	.endr

.balign 4096
tt2_kernel_image:
	.quad 1 << 21 | 1 << 10 | 1
	.quad 2 << 21 | 1 << 10 | 1
	.quad 3 << 21 | 1 << 10 | 1
	.quad 4 << 21 | 1 << 10 | 1
	.rep 508
		.quad 0
	.endr

.balign 4096
tt1_physical_map:
	.set GB, 0
	.rept 512
		.quad GB << 30 | 1 << 10 | 1
		.set GB, GB + 1
	.endr

.section .text

_start_hi:
	// Clear BSS.
	ldr	x5, =__bss_start
	ldr	w6, =__bss_size
1:	str	xzr, [x5], #8
	subs	w6, w6, #8
	cbnz	w6, 1b

	// Some things in Zig's standard library use floating-point (e.g.
	// memcpy using q registers); make sure we don't trap these in EL1.
	mov	x0, #(0b11 << 20)
	msr	CPACR_EL1, x0

	mov	x0, x29
4:	b	kernelMain

.global __delay
__delay:
1:	sub	w0, w0, #1
	cbnz	w0, 1b
	ret
