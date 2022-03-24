PHDRS {
	bootstrap PT_LOAD FLAGS(4|2|1) AT(0x80000);
	kernel_text PT_LOAD FLAGS(4|1);
	kernel_data PT_LOAD FLAGS(4|2);
	kernel_rodata PT_LOAD FLAGS(4);
}

SECTIONS {
    . = 0x80000;

    __kernel_phys_start = .;

    /*
     * The bootstrap portion. This gets loaded at 0x80000 without the MMU
     * enabled. Its only job is to enable the MMU and set up a sane execution
     * environment for the kernel proper, which gets mapped into a higher
     * address.
     */

    .bootstrap : {
        *(.bootstrap)
    } :bootstrap

    /*
     * The kernel proper.
     */

    __bootstrap_end = .;
    __bootstrap_len = . - __kernel_phys_start;

    . = 0x0000f00000000000 + __bootstrap_len;

    .text : AT(__bootstrap_end) ALIGN(0x1000) {
        KEEP(*(.text))
    } :kernel_text
    . = ALIGN(4096);

    .rodata : {
        *(.rodata)
    } :kernel_rodata
    . = ALIGN(4096);

    .data : {
        *(.data)
    } :kernel_data
    . = ALIGN(4096);

    __bss_start = .;
    .bss : {
        *(.bss)
    }
    . = ALIGN(4096);
    __bss_size = . - __bss_start;

    __kernel_phys_end = LOADADDR(.bss) + __bss_size;
    __kernel_size = __kernel_phys_end - __kernel_phys_start;
}
