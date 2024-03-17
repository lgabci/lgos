# LGOS main makefile

.SUFFIXES:
.DELETE_ON_ERROR:

.PHONY: all
all:

srcroot := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
bldroot := /tmp/lgos

# swithing path to soruce/build directory
define to-src
$(abspath $(patsubst $(bldroot)/bld/%,$(srcroot)/src/%,$1))
endef

define to-bld
$(abspath $(patsubst $(srcroot)/src/%,$(bldroot)/bld/%,$1))
endef

# canned recipes
define run-as
	$(AS) $(ASFLAGS) -I$(<D) -Wa,--MD,$(@:.o=.d) -o $@ $<
	a=$$(awk -v obj=$@ -v src=$< -f $(srcroot)/misc/awk-phony-dep.awk \
	  $(@:.o=.d)); echo "$$a" >>$(@:.o=.d)
endef

define run-cc
	$(CC) $(CFLAGS) -I$(srcdir) -o $@ $<
endef

define run-ld
	$(LD) $(LDFLAGS) -T $(call to-src,$(@:.elf=.ld)) -o $@ $^ -lgcc
endef

define run-bin
	$(OBJCOPY) $(OBJCOPYFLAGS) $< $@
endef


# include a makefile.mk
# $1 = makefile.mk
define inclmk
srcdir := $(abspath $(patsubst %/,%,$(dir $1)))
blddir := $$(call to-bld,$$(srcdir))

$(blddir):
	mkdir -p $$@

include $1

endef

%.elf:
	$(run-ld)

%.bin:
	$(run-bin)


findfiles = $(foreach d,$(wildcard $1/*),\
$(wildcard $(d)/$2) $(call findfiles,$(d),$2)\
)

mkfiles := $(call findfiles,.,makefile.mk)
$(foreach m,$(mkfiles),$(eval $(call inclmk,$m)))

dfiles := $(call findfiles,$(bldroot),*.d)
ifneq ($(dfiles),)
include $(dfiles)
endif

.PHONY: clean
clean:
	rm -rf $(bldroot)
