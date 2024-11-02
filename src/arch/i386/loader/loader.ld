OUTPUT_ARCH(i386)
OUTPUT_FORMAT(elf32-i386)
ENTRY(start)

PHDRS {
  text PT_LOAD;
  data PT_LOAD;
  bss  PT_LOAD;
}

MEMORY {
  ram  (rwx) : ORIGIN = 0,          LENGTH = 0x10000
}

SECTIONS {
  .text : {
    *(.itext)
    *(.text)
  } >ram :text

  . = ALIGN (CONSTANT (COMMONPAGESIZE));

  .data : ALIGN(1) {
    *(.data)
  } >ram :data

  .bss : {
    *(.bss)
  } >ram :bss
}
