# LGOS i386 makefile

CC := x86_64-elf-gcc
AS := x86_64-elf-gcc
OBJDUMP := x86_64-elf-objdump
OBJCOPY := x86_64-elf-objcopy
STRIP := x86_64-elf-strip
LD := x86_64-elf-ld

include $(getcurdir)/boot/makefile.mk
