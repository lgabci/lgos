OUTPUT_ARCH(i386)
OUTPUT_FORMAT(elf32-i386)
ENTRY(start)

MEMORY {
  ram0      : ORIGIN = 0x000, LENGTH = 0x00da
  timestamp : ORIGIN = 0x0da, LENGTH = 0x0006
  ram1      : ORIGIN = 0x0e0, LENGTH = 0x00d8
  bsign     : ORIGIN = 0x1fe, LENGTH = 0x0002
  bss       : ORIGIN = 0x200, LENGTH = 0x0200
}

SECTIONS {
  .text : ALIGN(1) {
    *(.text)
  } >ram0

  .data : ALIGN(1) {
    *(.data)
  } >ram0

  .bootsign : {
    BYTE(0x55)
    BYTE(0xaa)
  } >bsign

  .bss : {
    *(.bss)
    *(COMMON)
  } >bss
}
