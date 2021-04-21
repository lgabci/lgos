OUTPUT_ARCH(i386)
OUTPUT_FORMAT(elf32-i386)
ENTRY(start)

SECTIONS {
  _BIN_START = .;

  .text : ALIGN(1) {
    *(.itext)
    *(.text)
  }

  .data : ALIGN(1) {
    *(.data)
  }

  _BIN_SIZE = . - _BIN_START;

  .bss : {
    *(.bss)
    *(COMMON)
  }
}
