# LGOS i386 boot makefile

$(blddir)/init_mbr.o: ASFLAGS +=-Wa,--defsym,BSTYPE_MBR=1
$(blddir)/init_mbr.o: $(srcdir)/init.s | $(blddir)
	$(run-as)

$(blddir)/mbr.elf: $(blddir)/init_mbr.o $(blddir)/mbr.o $(blddir)/video.o
	$(run-ld)

$(blddir)/mbr.bin: $(blddir)/mbr.elf $(proba)
	$(run-bin)
