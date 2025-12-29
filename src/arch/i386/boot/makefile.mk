# LGOS i386 boot makefile

include $(SOURCEDIR)/common.mk

$(call push,CFLAGS)
CFLAGS := $(call update_var,CFLAGS,-m32,-m16)

$(builddir)/%.o: CFLAGS := $(CFLAGS)

boot_mbr_elf := $(builddir)/mbr.elf

$(boot_mbr_elf): LDFLAGS := $(LDFLAGS) -T $(sourcedir)/mbr.ld

$(boot_mbr_elf): $(addprefix $(builddir)/,init_mbr.o mbr.o video.o disk.o \
misc.o) | $(builddir)

$(builddir)/init_mbr.o: $(sourcedir)/init.S
$(builddir)/init_mbr.o: CFLAGS := $(CFLAGS) -Wa,--defsym,MBR=1


boot_mbr_bin := $(builddir)/mbr.bin

$(boot_mbr_bin): $(boot_mbr_elf)


boot_fat_elf := $(builddir)/fat.elf

$(boot_fat_elf): LDFLAGS := $(LDFLAGS) -T $(sourcedir)/fat.ld

$(boot_fat_elf): $(addprefix $(builddir)/,init_fat.o load_fat.o video.o \
disk.o misc.o) | $(builddir)

$(builddir)/init_fat.o: $(sourcedir)/init.S
$(builddir)/init_fat.o: CFLAGS := $(CFLAGS) -Wa,--defsym,FAT=1

$(builddir)/load_fat.o: $(sourcedir)/load.S
$(builddir)/load_fat.o: CFLAGS := $(CFLAGS) -Wa,--defsym,FAT=1


boot_fat_bin := $(builddir)/fat.bin

$(boot_fat_bin): $(boot_fat_elf)


boot_ext2_elf := $(builddir)/ext2.elf

$(boot_ext2_elf): LDFLAGS := $(LDFLAGS) -T $(sourcedir)/ext2.ld

$(boot_ext2_elf): $(addprefix $(builddir)/,init_ext2.o load_ext2.o video.o \
disk.o misc.o) | $(builddir)

$(builddir)/init_ext2.o: $(sourcedir)/init.S

$(builddir)/load_ext2.o: $(sourcedir)/load.S
$(builddir)/load_ext2.o: CFLAGS := $(CFLAGS) -Wa,--defsym,EXT2=1


boot_ext2_bin := $(builddir)/ext2.bin

$(boot_ext2_bin): $(boot_ext2_elf)

$(call pop,CFLAGS)
