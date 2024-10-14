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
  bpb  (r)   : ORIGIN = 0x3,        LENGTH = 0x57
  ram  (rwx) : ORIGIN = 0x5a,       LENGTH = 0x1a4
  bsgn (r)   : ORIGIN = 0x1fe,      LENGTH = 0x02
  bss  (rw)  : ORIGIN = 0x200,      LENGTH = 0x200
}

SECTIONS {
  .text : {
    *(.jtext)
  } >jram :text

  .text : {
    *(.itext)
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
