# LGOS i386 loader makefile

include $(SOURCEDIR)/common.mk

$(call push,CFLAGS)
CFLAGS := $(call update_var,CFLAGS,-m32,-m16)

$(builddir)/%.o: CFLAGS := $(CFLAGS)

loader_elf := $(builddir)/loader.elf

$(loader_elf): LDFLAGS := $(LDFLAGS) -T $(sourcedir)/loader.ld

$(loader_elf): $(addprefix $(builddir)/,init.o main.o video.o misc.o \
disk.o) | $(builddir)

loader_bin := $(builddir)/loader.bin

$(loader_bin): $(loader_elf)

$(call pop,CFLAGS)
