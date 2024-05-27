/* Linker script for RISC-V */

OUTPUT_ARCH(riscv)

/* Symbols for the RAM section */
_ram_start = 0x10000000;
_ram_end = _ram_start + 64;  /* 64 bytes RAM */

/* Specify the memory regions */
MEMORY
{
    ROM (rx) : ORIGIN = 0x00002000, LENGTH = 700
    RAM (rwx) : ORIGIN = 0x10000000, LENGTH = 64
}

/* Provide stack address for reset handler */
PROVIDE(stack = _stack_end);


ENTRY(reset_handler)

SECTIONS
{
    /* Text section */
    .text :
    {
        *(.text)
        *(.rodata)
    } > ROM

    /* Data section */
    .data :
    {
        . = ALIGN(4);
        _data = .;
        *(.data)
        _edata = .;
    } > RAM

    /* BSS section */
    .bss :
    {
        . = ALIGN(4);
        _bss = .;
        *(.bss)
        *(COMMON)
        _ebss = .;
    } > RAM

    /* Stack section */
    .stack (NOLOAD) :
    {
        . = ALIGN(4);
        _stack_start = .;
        . += 50;
        _stack_end = .;
    } > RAM
}
