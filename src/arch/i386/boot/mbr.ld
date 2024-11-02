OUTPUT_ARCH(i386)
OUTPUT_FORMAT(elf32-i386)
ENTRY(start)

PHDRS {
  text PT_LOAD;
  data PT_LOAD;
  bsgn PT_LOAD;
  bss  PT_LOAD;
}

MEMORY {
  ram  (rwx) : ORIGIN = 0x0,        LENGTH = 0x1b8
  bsgn (r)   : ORIGIN = 0x1fe,      LENGTH = 0x2
  bss  (rw)  : ORIGIN = 0x200,      LENGTH = 0x200
}

SECTIONS {
  __start = .;
  __text_start = .;

  .text : {
    *(.itext)
    *(.text)
  } >ram :text

  __text_end = .;
  __data_start = .;

  .data : ALIGN(1) {
    *(.data)
  } >ram :data

  .bootsign : {
    BYTE(0x55)
    BYTE(0xaa)
  } >bsgn :bsgn

  __data_end = .;
  __bss_start = .;

  .bss : {
    *(.bss)
  } >bss :bss

  __bss_end = .;
  . = ALIGN(0x200);
  __end = .;
}
