MEMORY
{
    ICCM : ORIGIN = 0x00000000, LENGTH = 32K
    DCCM : ORIGIN = 0x80000000, LENGTH = 32K
    RAM  : ORIGIN = 0x10000000, LENGTH = 128M
}

/* Have to put all code sections in ICCM. Cannot put everything into RAM,
 * because .ivt+.init must be at 0x0 for GNU linker, and cannot put .text in
 * RAM and .init in ICCM, because that would create a long jump, that doesn't
 * fir into S25 jump that might be present in crtbegin.o */
REGION_ALIAS("REGION_IVT",    ICCM)
REGION_ALIAS("REGION_INIT",   ICCM)
REGION_ALIAS("REGION_TEXT",   ICCM)
REGION_ALIAS("REGION_RODATA", RAM)
REGION_ALIAS("REGION_DATA",   RAM)
REGION_ALIAS("REGION_SDATA",  RAM)
REGION_ALIAS("REGION_SBSS",   RAM)
REGION_ALIAS("REGION_BSS",    RAM)
REGION_ALIAS("REGION_HEAP",   RAM)
REGION_ALIAS("REGION_STACK",  RAM)

ENTRY(__start)

SECTIONS
{
    .ivt 0x00 :
    {
      KEEP (*(.ivt));
    } > REGION_IVT
    .init 0x100 :
    {
        KEEP (*(.init));
    } > REGION_INIT
    .text :
    {
        *(.text .stub .text.* .gnu.linkonce.t.*)
    } > REGION_TEXT
    .rodata :
    {
        *(.rodata .rodata.*)
    } > REGION_RODATA
    .data :
    {
        *(.data .data.* .gnu.linkonce.d.*)
	SORT(CONSTRUCTORS)
    } > REGION_DATA
    .got            :
    {
	*(.got.plt) *(.got)
    } > REGION_DATA
    .sdata :
    {
        __SDATA_BEGIN__ = .;
        *(.sdata .sdata.* .gnu.linkonce.s.*)
        _edata = .;
        PROVIDE (edata = .);
    } > REGION_SDATA
    .sbss :
    {
        __bss_start = .;
        PROVIDE (__sbss_start = .);
        PROVIDE (___sbss_start = .);
        *(.dynsbss)
        *(.sbss .sbss.* .gnu.linkonce.sb.*)
        *(.scommon)
        PROVIDE (__sbss_end = .);
        PROVIDE (___sbss_end = .);
    } > REGION_SBSS
    .bss :
    {
        *(.dynbss)
        *(.bss .bss.* .gnu.linkonce.b.*)
        *(COMMON)
        /* Align here to ensure that the .bss section occupies space up to
        _end. Align after .bss to ensure correct alignment even if the
        .bss section disappears because there are no input sections. */
        . = ALIGN(32 / 8);
        _end = .;
        PROVIDE (end = .);
    } > REGION_BSS
    .heap :
    {
        . = ALIGN(32 / 8);
        __start_heap = . ;
        . = . + (DEFINED(__HEAP_SIZE) ? __HEAP_SIZE : (DEFINED(__DEFAULT_HEAP_SIZE) ? __DEFAULT_HEAP_SIZE : 16k)) ;
        __end_heap = . ;
        . = ALIGN(0x8);
    } > REGION_HEAP
    .stack :
    {
        . = ALIGN(32 / 8);
        __stack = . ;
        . = . + (DEFINED(__STACK_SIZE) ? __STACK_SIZE : (DEFINED(__DEFAULT_STACK_SIZE) ? __DEFAULT_STACK_SIZE : 2k)) ;
        __stack_top = . ;
    } > REGION_STACK
}
