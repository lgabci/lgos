# LGOS i386 makefile

include $(SOURCEDIR)/common.mk

CC := x86_64-elf-gcc
AS := x86_64-elf-gcc
OBJDUMP := x86_64-elf-objdump
OBJCOPY := x86_64-elf-objcopy
STRIP := x86_64-elf-strip
LD := x86_64-elf-gcc

CFLAGS := $(CFLAGS) -m32

$(call include_file,boot/makefile.mk)
$(call include_file,loader/makefile.mk)
