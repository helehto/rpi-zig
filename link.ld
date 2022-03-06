SECTIONS {
    .text 0x80000 : {
        KEEP(*(.text.boot))
        *(.text)
        *(.text.*)
    }
    . = ALIGN(4096);

    .rodata : {
        *(.rodata)
    }
    . = ALIGN(4096);

    .data : {
        *(.data)
    }
    . = ALIGN(4096);

    __bss_start = .;
    .bss : {
        bss = .;
        *(.bss)
    }
    . = ALIGN(4096);
    __bss_size = . - __bss_start;
}
