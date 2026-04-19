# LGOS main makefile

MAKEFLAGS += -rR
.SUFFIXES:

ROOTSRCDIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
ROOTBLDDIR ?= /tmp/lgos
ARCH ?= i386

all: emu_hd_ext2

# canned recipes -------------------------------------------------------------
define CCOMP =
$(CC) $(CFLAGS) $(EXTRAFLAGS) -MMD -MP -MF $(patsubst %.o,%.d,$@) -o $@ $<
endef

define ASCOMP =
$(AS) $(ASFLAGS) $(EXTRAFLAGS) -MMD -MP -MF $(patsubst %.o,%.d,$@) -o $@ $<
endef

define ELF =
$(LD) $(LDFLAGS) $(EXTRAFLAGS) -Wl,-Map=$(patsubst %.elf,%.map,$@) -o $@ $^
endef

define BIN =
$(OBJCOPY) -O binary $< $@
endef

define MKDIR =
mkdir -p $@
endef

# common rules ---------------------------------------------------------------
%.o:
	$(if $(filter %.c,$<), \
	$(CCOMP), \
	$(if $(filter %.S,$<), \
	$(ASCOMP), \
	$(error Unknown recipe: $< -> $@)))

%.elf:
	$(ELF)

%.bin:
	$(BIN)

.PHONY: clean
clean:
	rm -rf $(ROOTBLDDIR)

# i386 -----------------------------------------------------------------------
ifeq ($(ARCH),i386)

.PHONY: all
all: emu_hd_ext2

EXTRA_FLAGS :=

CC := x86_64-elf-gcc
AS := x86_64-elf-gcc
OBJDUMP := x86_64-elf-objdump
OBJCOPY := x86_64-elf-objcopy
STRIP := x86_64-elf-strip
LD := x86_64-elf-gcc

CFLAGS := -c -Wall -Wextra -pedantic -Werror -ffreestanding -O3

ASFLAGS := -c -Wa,--fatal-warnings

LDFLAGS := -ffreestanding -nostdlib -nostdinc

# boot -----------------------------------------------------------------------
bootsrcdir := $(ROOTSRCDIR)/src/arch/$(ARCH)/boot
bootblddir := $(ROOTBLDDIR)/bld/arch/$(ARCH)/boot

-include $(wildcard $(bootblddir)/*.d)

$(bootblddir)/%.o: EXTRAFLAGS += -m16
$(bootblddir)/init.o: $(bootsrcdir)/init.S | $(bootblddir)
$(bootblddir)/video.o: $(bootsrcdir)/video.S | $(bootblddir)
$(bootblddir)/mbr.o: $(bootsrcdir)/mbr.S | $(bootblddir)
$(bootblddir)/misc.o: $(bootsrcdir)/misc.S | $(bootblddir)
$(bootblddir)/disk.o: $(bootsrcdir)/disk.S | $(bootblddir)

$(bootblddir)/mbr.elf: EXTRAFLAGS += -T $(bootsrcdir)/mbr.ld
$(bootblddir)/mbr.elf: $(addprefix $(bootblddir)/,init.o video.o mbr.o misc.o \
disk.o)

$(bootblddir)/mbr.bin: $(bootblddir)/mbr.elf

$(bootblddir):
	$(MKDIR)

# loader ---------------------------------------------------------------------
loadersrcdir := $(ROOTSRCDIR)/src/arch/$(ARCH)/loader
loaderblddir := $(ROOTBLDDIR)/bld/arch/$(ARCH)/loader

-include $(wildcard $(loaderblddir)/*.d)

$(loaderblddir)/%.o: EXTRAFLAGS += -m16
$(loaderblddir)/init.o: $(loadersrcdir)/init.S | $(loaderblddir)

$(loaderblddir)/loader.elf: EXTRAFLAGS += -T $(loadersrcdir)/loader.ld
$(loaderblddir)/loader.elf: $(addprefix $(loaderblddir)/,init.o)

$(loaderblddir)/loader.bin: $(loaderblddir)/loader.elf

$(loaderblddir):
	$(MKDIR)

# kernel ---------------------------------------------------------------------
kernelsrcdir := $(ROOTSRCDIR)/src/arch/$(ARCH)/kernel
kernelblddir := $(ROOTBLDDIR)/bld/arch/$(ARCH)/kernel

-include $(wildcard $(kernelblddir)/*.d)

$(kernelblddir)/%.o: EXTRAFLAGS += -m32
$(kernelblddir)/init.o: $(kernelsrcdir)/init.S | $(kernelblddir)

$(kernelblddir)/kernel.elf: EXTRAFLAGS += -T $(kernelsrcdir)/kernel.ld
$(kernelblddir)/kernel.elf: $(addprefix $(kernelblddir)/,init.o)

$(kernelblddir)/kernel.bin: $(kernelblddir)/kernel.elf

$(kernelblddir):
	$(MKDIR)

# emu ------------------------------------------------------------------------
emusrcdir := $(ROOTSRCDIR)/src/arch/$(ARCH)/emu
emublddir := $(ROOTBLDDIR)/bld/arch/$(ARCH)/emu

$(emublddir)/hd_ext2.img: $(bootblddir)/mbr.bin $(loaderblddir)/loader.bin \
$(kernelblddir)/kernel.bin | $(emublddir)
	$(emusrcdir)/mkimg.sh $@ $^

$(emublddir):
	$(MKDIR)

.PHONY: emu_hd_ext2
emu_hd_ext2: $(emublddir)/hd_ext2.img
	$(emusrcdir)/emu.sh hd $(emublddir)/hd_ext2.img

endif
