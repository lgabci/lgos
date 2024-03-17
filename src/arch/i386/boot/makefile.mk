# LGOS i386 boot makefile

#$(blddir)/init-mbr.o: ASFLAGS += -Wa,--defsym,BSTYPE_MBR=1
#$(blddir)/init-mbr.o: $(srcdir)/init.s | $(blddir)
#	$(run-as)

#$(blddir)/mbr.elf: $(blddir)/init-mbr.o $(blddir)/mbr.o $(blddir)/video.o

#$(blddir)/mbr.bin: $(blddir)/mbr.elf

srcs := init.s:init_mbr.o mbr.s video.s
trg := mbr.elf


define recipe
src := $(word 1,$(subst :, ,$1))
obj := $(word 2,$(subst :, ,$1))

asrc := $$(filter %.s,$$(src))
csrc := $$(filter %.c,$$(src))

ifeq ($$(obj),)
obj := $$(asrc:.s=.o)$$(csrc:.c=.o)
endif

ifneq ($$(asrc),)
$(blddir)/$$(obj): ASLASGS := $(ASFLAGGS)
endif
ifneq ($$(csrc),)
$(blddir)/$$(obj): CLASGS := $(CFLAGGS)
endif

$(blddir)/$$(obj): $(srcdir)/$$(src) | $(blddir)
ifneq ($$(asrc),)
	$$(run-as)
endif
ifneq ($$(csrc),)
	$$(run-cc)
endif

all: $(blddir)/$$(obj)  ###
endef

$(info -----)
$(foreach s,$(srcs),$(eval $(call recipe,$s)))
$(info -----)
