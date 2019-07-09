
OUTPUT_FORMAT("binary");
OUTPUT_ARCH(i386);
ENTRY(MikanMain);

SECTIONS {
    .head 0x0 : {
        LONG(128 * 1024)
        LONG(0x6e616b694d)
        LONG(0)
        LONG(0x310000)
        LONG(SIZEOF(.data))
        LONG(LOADADDR(.data))
        LONG(0xe9000000)
        LONG(MikanMain - 0x20)
        LONG(24 * 1024)
    }

    .text : { *(.text) }
    .data 0x310000 : AT ( ADDR(.text) + SIZEOF(.text) ) {
        *(.data)
        *(.rodata*)
        *(.bss)
    }

    /DISCARD/ : { *(.eh_frame) }
}
