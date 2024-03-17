# LGOS i386 makefile

AS := i386-elf-gcc
ASFLAGS := -ffreestanding -c -pedantic -Wall

CC := i386-elf-gcc
CFLAGS := -ffreestanding -c -pedantic -Wall

LD := i386-elf-gcc
LDFLAGS := -ffreestanding -nostdlib

OBJCOPY := i386-elf-objcopy
OBJCOPYFLAGS := -O binary
