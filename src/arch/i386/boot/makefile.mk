# LGOS i386 boot makefile

$(info MAKEFILE_LIST = $(MAKEFILE_LIST))  ###
$(info $(sourcedir) -> $(builddir); $(BUILDDIR); $(getcurdir))  ###

$(builddir)/mbr.elf: $(addprefix $(builddir)/,init.o mbr.o video.o disk.o \
misc.o)

#$(builddir)/disk.o: $(sourcedir)/disk.S
