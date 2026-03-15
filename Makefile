# LGOS main makefile

MAKEFLAGS += -rR
.SUFFIXES:

ROOTSRCDIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
ROOTBLDDIR ?= /tmp/lgos
ARCH ?= i386

# canned recipes -------------------------------------------------------------
define CCOMP =
$(CC) $(CFLAGS) $(EXTRAFLAGS) -o $@ $<
endef

define ASCOMP =
$(AS) $(ASFLAGS) $(EXTRAFLAGS) -o $@ $<
endef

define ELFCOMP =
$(LD) $(LDFLAGS) $(EXTRAFLAGS) -o $@ $^
endef

define MKDIR =
mkdir -p $@
endef

# i386 -----------------------------------------------------------------------
ifeq ($(ARCH),i386)

.PHONY: all
all: /tmp/lgos/bld/arch/i386/boot/mbr.elf \
/tmp/lgos/bld/arch/i386/loader/loader.elf \
/tmp/lgos/bld/arch/i386/kernel/kernel.elf  ###


EXTRA_FLAGS :=

CC := x86_64-elf-gcc
AS := x86_64-elf-gcc
OBJDUMP := x86_64-elf-objdump
OBJCOPY := x86_64-elf-objcopy
STRIP := x86_64-elf-strip
LD := x86_64-elf-gcc

CFLAGS := -Wall -Wextra -pedantic -Werror -ffreestanding -O3 -c

ASFLAGS := $(CFLAGS)

LDFLAGS := -ffreestanding -nostdlib -nostdinc



# boot -----------------------------------------------------------------------
bootsrcdir := $(ROOTSRCDIR)/src/arch/$(ARCH)/boot
bootblddir := $(ROOTBLDDIR)/bld/arch/$(ARCH)/boot

$(bootblddir)/%.o: EXTRAFLAGS += -m16
$(bootblddir)/init.o: $(bootsrcdir)/init.S | $(bootblddir)

$(bootblddir)/mbr.elf: EXTRAFLAGS += -T $(bootsrcdir)/mbr.ld
$(bootblddir)/mbr.elf: $(bootblddir)/init.o

$(bootblddir):
	$(MKDIR)

# loader ---------------------------------------------------------------------
loadersrcdir := $(ROOTSRCDIR)/src/arch/$(ARCH)/loader
loaderblddir := $(ROOTBLDDIR)/bld/arch/$(ARCH)/loader

$(loaderblddir)/%.o: EXTRAFLAGS += -m16
$(loaderblddir)/init.o: $(loadersrcdir)/init.S | $(loaderblddir)

$(loaderblddir)/loader.elf: EXTRAFLAGS += -T $(loadersrcdir)/loader.ld
$(loaderblddir)/loader.elf: $(loaderblddir)/init.o

$(loaderblddir):
	$(MKDIR)


# kernel ---------------------------------------------------------------------
kernelsrcdir := $(ROOTSRCDIR)/src/arch/$(ARCH)/kernel
kernelblddir := $(ROOTBLDDIR)/bld/arch/$(ARCH)/kernel

$(kernelblddir)/%.o: EXTRAFLAGS += -m32
$(kernelblddir)/init.o: $(kernelsrcdir)/init.S | $(kernelblddir)

$(kernelblddir)/kernel.elf: EXTRAFLAGS += -T $(kernelsrcdir)/kernel.ld
$(kernelblddir)/kernel.elf: $(kernelblddir)/init.o

$(kernelblddir):
	$(MKDIR)

endif


# common rules ---------------------------------------------------------------
%.o:
	$(if $(filter %.c,$<), \
	$(CCOMP), \
	$(if $(filter %.S,$<), \
	$(ASCOMP), \
	$(error Unknown recipe: $< -> $@)))

%.elf:
	$(ELFCOMP)

.PHONY: clean
clean:
	rm -rf $(ROOTBLDDIR)
