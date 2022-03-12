.section .text

save_regs:
	str	q31, [sp, #-16]!
	str	q30, [sp, #-16]!
	str	q29, [sp, #-16]!
	str	q28, [sp, #-16]!
	str	q27, [sp, #-16]!
	str	q26, [sp, #-16]!
	str	q25, [sp, #-16]!
	str	q24, [sp, #-16]!
	str	q23, [sp, #-16]!
	str	q22, [sp, #-16]!
	str	q21, [sp, #-16]!
	str	q20, [sp, #-16]!
	str	q19, [sp, #-16]!
	str	q18, [sp, #-16]!
	str	q17, [sp, #-16]!
	str	q16, [sp, #-16]!
	str	q15, [sp, #-16]!
	str	q14, [sp, #-16]!
	str	q13, [sp, #-16]!
	str	q12, [sp, #-16]!
	str	q11, [sp, #-16]!
	str	q10, [sp, #-16]!
	str	q9, [sp, #-16]!
	str	q8, [sp, #-16]!
	str	q7, [sp, #-16]!
	str	q6, [sp, #-16]!
	str	q5, [sp, #-16]!
	str	q4, [sp, #-16]!
	str	q3, [sp, #-16]!
	str	q2, [sp, #-16]!
	str	q1, [sp, #-16]!
	str	q0, [sp, #-16]!
	stp	x28, x29, [sp, #-16]!
	stp	x26, x27, [sp, #-16]!
	stp	x24, x25, [sp, #-16]!
	stp	x22, x23, [sp, #-16]!
	stp	x20, x21, [sp, #-16]!
	stp	x18, x19, [sp, #-16]!
	stp	x16, x17, [sp, #-16]!
	stp	x14, x15, [sp, #-16]!
	stp	x12, x13, [sp, #-16]!
	stp	x10, x11, [sp, #-16]!
	stp	x8, x9, [sp, #-16]!
	stp	x6, x7, [sp, #-16]!
	stp	x4, x5, [sp, #-16]!
	stp	x2, x3, [sp, #-16]!
	stp	x0, x1, [sp, #-16]!
	mov	x0, sp
	ret

restore_regs:
	ldp	x0, x1, [sp, #16]!
	ldp	x2, x3, [sp, #16]!
	ldp	x4, x5, [sp, #16]!
	ldp	x6, x7, [sp, #16]!
	ldp	x8, x9, [sp, #16]!
	ldp	x10, x11, [sp, #16]!
	ldp	x12, x13, [sp, #16]!
	ldp	x14, x15, [sp, #16]!
	ldp	x16, x17, [sp, #16]!
	ldp	x18, x19, [sp, #16]!
	ldp	x20, x21, [sp, #16]!
	ldp	x22, x23, [sp, #16]!
	ldp	x24, x25, [sp, #16]!
	ldp	x26, x27, [sp, #16]!
	ldp	x28, x29, [sp, #16]!
	ldr	q0, [sp, #16]!
	ldr	q1, [sp, #16]!
	ldr	q2, [sp, #16]!
	ldr	q3, [sp, #16]!
	ldr	q4, [sp, #16]!
	ldr	q5, [sp, #16]!
	ldr	q6, [sp, #16]!
	ldr	q7, [sp, #16]!
	ldr	q8, [sp, #16]!
	ldr	q9, [sp, #16]!
	ldr	q10, [sp, #16]!
	ldr	q11, [sp, #16]!
	ldr	q12, [sp, #16]!
	ldr	q13, [sp, #16]!
	ldr	q14, [sp, #16]!
	ldr	q15, [sp, #16]!
	ldr	q16, [sp, #16]!
	ldr	q17, [sp, #16]!
	ldr	q18, [sp, #16]!
	ldr	q19, [sp, #16]!
	ldr	q20, [sp, #16]!
	ldr	q21, [sp, #16]!
	ldr	q22, [sp, #16]!
	ldr	q23, [sp, #16]!
	ldr	q24, [sp, #16]!
	ldr	q25, [sp, #16]!
	ldr	q26, [sp, #16]!
	ldr	q27, [sp, #16]!
	ldr	q28, [sp, #16]!
	ldr	q29, [sp, #16]!
	ldr	q30, [sp, #16]!
	ldr	q31, [sp, #16]!
	ret

.macro trampoline target
	.global \target

	// Save the link register separately to avoid clobbering it when
	// calling save_regs().
	str	x30, [sp, #-8]!

	bl	save_regs
	bl	\target
	bl	restore_regs
	ldr	x30, [sp, #8]!
	eret

	// Pad to next handler.
	.balign 0x80
.endm

.balign 0x800
.global __vector_table_el1
__vector_table_el1:

curr_el_sp0_sync:
	trampoline handleCurrElSp0Sync

curr_el_sp0_irq:
	trampoline handleCurrElSp0Irq

curr_el_sp0_fiq:
	trampoline handleCurrElSp0Fiq

curr_el_sp0_serror:
	trampoline handleCurrElSp0Serror

curr_el_spx_sync:
	trampoline handleCurrElSpxSync

curr_el_spx_irq:
	trampoline handleCurrElSpxIrq

curr_el_spx_fiq:
	trampoline handleCurrElSpxFiq

curr_el_spx_serror:
	trampoline handleCurrElSpxFiq

lower_el_aarch64_sync:
	trampoline handleLowerElAarch64Sync

lower_el_aarch64_irq:
	trampoline handleLowerElAarch64Irq

lower_el_aarch64_fiq:
	trampoline handleLowerElAarch64Fiq

lower_el_aarch64_serror:
	trampoline handleLowerElAarch64Serror

lower_el_aarch32_sync:
	trampoline handleLowerElAarch32Sync

lower_el_aarch32_irq:
	trampoline handleLowerElAarch32Irq

lower_el_aarch32_fiq:
	trampoline handleLowerElAarch32Fiq

lower_el_aarch32_serror:
	trampoline handleLowerElAarch32Serror
