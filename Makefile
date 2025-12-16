# LGOS main makefile

MAKEFLAGS += --no-builtin-rules

.SUFFIXES:

ifndef ARCH
$(error Achitecture is not set in variable ARCH.)
endif

ifndef BUILDDIR
$(error Build directory is not set in variable BUILDDIR.)
endif

getcurdir = $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))

sourcedir = $(abspath $(getcurdir))
builddir = $(abspath $(BUILDDIR)/$(getcurdir))

$(info $(sourcedir) -> $(builddir); $(BUILDDIR); $(getcurdir))  ###
$(builddir)/%.o: $(sourcedir)/%.S
	echo ooooo $@ $<

$(builddir)/%.elf:
	echo ELF $@ $^

$(builddir)/%.elf: | $(builddir)

$(builddir)/%.o: | $(builddir)

#$(builddir):
#	echo mkdir $(builddir)

include src/arch/$(ARCH)/makefile.mk
