OUTPUT_ARCH(i386)
OUTPUT_FORMAT(binary)
ENTRY(_start)

PHDRS {
  text PT_LOAD;
  data PT_LOAD;
  bsgn PT_LOAD;
  bss  PT_LOAD;
}

MEMORY {
  ram  (rwx) : ORIGIN = 0,          LENGTH = 0x1be
  bsgn (r)   : ORIGIN = 0x1fe,      LENGTH = 2
  bss  (rw)  : ORIGIN = 0x200,      LENGTH = 0x200
}

SECTIONS {
  .text : {
    *(.text)
  } >ram :text

  . = ALIGN (CONSTANT (COMMONPAGESIZE));

  .data : ALIGN(1) {
    *(.data)
  } >ram :data

  .bootsign : {
    BYTE(0x55)
    BYTE(0xaa)
  } >bsgn :bsgn

  .bss : {
    *(.bss)
  } >bss :bss
}
