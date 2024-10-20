OUTPUT_ARCH(i386)
OUTPUT_FORMAT(elf32-i386)
ENTRY(jstart)

PHDRS {
  text PT_LOAD;
  data PT_LOAD;
  bsgn PT_LOAD;
  bss  PT_LOAD;
}

MEMORY {
  jram (rwx) : ORIGIN = 0x0,        LENGTH = 0x3
  ram  (rwx) : ORIGIN = 0x5a,       LENGTH = 0x1a4
  bsgn (r)   : ORIGIN = 0x1fe,      LENGTH = 0x02
  bss  (rw)  : ORIGIN = 0x200,      LENGTH = 0x200
}

SECTIONS {
  __start = .;
  __text_start = .;

  .text : ALIGN(1) {
    *(.jtext)
  } >jram :text

  .text : ALIGN(1) {
    *(.itext)
    *(.text)
  } >ram :text

  __text_end = .;
  __data_start = .;

  .data : ALIGN(1) {
    *(.data)
    . = 0x1fe - __data_start;
  } >ram :data

  .bootsign : {
    BYTE(0x55)
    BYTE(0xaa)
  } >bsgn :bsgn

  __data_end = .;
  __bss_start = .;

  .bss : ALIGN(1) {
    *(.bss)
  } >bss :bss

  __bss_end = .;
  __end = .;
}
