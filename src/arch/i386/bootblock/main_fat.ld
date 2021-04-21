OUTPUT_ARCH(i386)
OUTPUT_FORMAT(elf32-i386)
ENTRY(start)

MEMORY {
  jram      : ORIGIN = 0x000, LENGTH = 0x0003
  ram       : ORIGIN = 0x05a, LENGTH = 0x01a4
  bsign     : ORIGIN = 0x1fe, LENGTH = 0x0002
  bss       : ORIGIN = 0x200, LENGTH = 0x0200
}

SECTIONS {
  _BIN_START = .;

  .jtext : ALIGN(1) {
    *(.jtext)
  } >jram

  .text : ALIGN(1) {
    *(.itext)
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
