OUTPUT_ARCH(i386)
OUTPUT_FORMAT(elf32-i386)
ENTRY(start)

MEMORY {
  ram       : ORIGIN = 0x000, LENGTH = 0x01fe
  bsign     : ORIGIN = 0x1fe, LENGTH = 0x0002
  bss       : ORIGIN = 0x200, LENGTH = 0x0200
}

SECTIONS {
  _BIN_START = .;

  .text : ALIGN(1) {
    */common.s.o(.text)
    *(.text)
  } >ram

  .data : ALIGN(1) {
    *(.data)
  } >ram

  .bootsign : {
    BYTE(0x55)
    BYTE(0xaa)
  } >bsign

  _BIN_SIZE = . - _BIN_START;

  .bss : {
    *(.bss)
    *(COMMON)
  } >bss
}
