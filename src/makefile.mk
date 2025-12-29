# LGOS src makefile

include $(SOURCEDIR)/common.mk

CFLAGS := -Wall -Wextra -pedantic -Werror -ffreestanding -O3 \
          -Wa,--fatal-warnings

#x86_64-elf-gcc -Isrc/arch/i386/boot/mbr.elf.p -Isrc/arch/i386/boot -I../../home/gabci/projects/lgos/src/arch/i386/boot -fdiagnostics-color=always -D_FILE_OFFSET_BITS=64 -Wall -Winvalid-pch -Wextra -Wpedantic -Wcast-qual -Wconversion -Wfloat-equal -Wformat=2 -Winline -Wmissing-declarations -Wredundant-decls -Wshadow -Wundef -Wuninitialized -Wwrite-strings -Wdisabled-optimization -Wpacked -Wpadded -Wmultichar -Wswitch-default -Wswitch-enum -Wunused-macros -Wmissing-include-dirs -Wunsafe-loop-optimizations -Wstack-protector -Wstrict-overflow=5 -Warray-bounds=2 -Wlogical-op -Wstrict-aliasing=3 -Wvla -Wdouble-promotion -Wsuggest-attribute=const -Wsuggest-attribute=noreturn -Wsuggest-attribute=pure -Wtrampolines -Wvector-operation-performance -Wsuggest-attribute=format -Wdate-time -Wformat-signedness -Wnormalized=nfc -Wduplicated-cond -Wnull-dereference -Wshift-negative-value -Wshift-overflow=2 -Wunused-const-variable=2 -Walloca -Walloc-zero -Wformat-overflow=2 -Wformat-truncation=2 -Wstringop-overflow=3 -Wduplicated-branches -Wcast-align=strict -Wsuggest-attribute=cold -Wsuggest-attribute=malloc -Wattribute-alias=2 -Wanalyzer-too-complex -Warith-conversion -Wbidi-chars=ucn -Wopenacc-parallelism -Wtrivial-auto-var-init -Wbad-function-cast -Wmissing-prototypes -Wnested-externs -Wstrict-prototypes -Wold-style-definition -Winit-self -Wc++-compat -Werror -O3 -pedantic -ffreestanding -Wa,--fatal-warnings -m32 -Wa,--defsym,MBR=1 -MD -MQ src/arch/i386/boot/mbr.elf.p/mbr.S.o -MF src/arch/i386/boot/mbr.elf.p/mbr.S.o.d -o src/arch/i386/boot/mbr.elf.p/mbr.S.o -c ../../home/gabci/projects/lgos/src/arch/i386/boot/mbr.S  ###


LDFLAGS := -nostdlib -Wl,--fatal-warnings


CCOMP = $(CC) $(CFLAGS) -c -o $@ $<

LDCOMP = $(LD) $(LDFLAGS) -o $@ $^

OBJCOMP = $(OBJCOPY) -O binary $< $@


$(builddir)/%.o: $(sourcedir)/%.S
	$(CCOMP)

$(builddir)/%.o: $(sourcedir)/%.c
	$(CCOMP)

$(builddir)/%.o:
	$(CCOMP)

$(builddir)/%.elf:
	$(LDCOMP)

%.bin: %.elf
	$(OBJCOMP)

$(call include_file,arch/$(ARCH)/makefile.mk)
