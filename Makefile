# LGOS main makefile

MAKEFLAGS += --no-builtin-rules

.SUFFIXES:

# variables for path
# name         | value
# -------------|--------------------------------------------------------------
# SOURCEDIR    | absolute path of source root directory
# BUILDDIR     | absolute path of build root directory, from env variable

ifndef ARCH
$(error Achitecture is not set in environment variable ARCH.)
endif

ifndef BUILDDIR
$(error Build directory is not set in environment variable BUILDDIR.)
endif

SOURCEDIR := $(CURDIR)

ESC := ~
SPACE := $(subst ,, )

# push variable into STACK_variable_name list
# $(push variable_name)
define push
$(eval STACK_$(1) := $(subst $$,$$$$,$(subst $(SPACE),$(ESC),$(value $(1)))) \
$(STACK_$(1)))
endef

# pop variable from STACK_variable_name list
# $(pop variable_name)
define pop
$(eval $(1) $(if $(filter recursive,$(flavor $(1))),,:)= \
$(subst $(ESC),$(SPACE),$(firstword $(STACK_$(1)))))
$(eval STACK_$(1) := $(wordlist 2,$(words $(value STACK_$(1))),$(value \
STACK_$(1))))
endef

# include file, save relsourcedir, relbuilddir, sourcedir, builddir
# variables into stack
# $(include_file include.mk)
define include_file
$(call push,relsourcedir)
$(call push,relbuilddir)
$(call push,sourcedir)
$(call push,builddir)
$(eval include $(sourcedir)/$(1))
$(call pop,relsourcedir)
$(call pop,relbuilddir)
$(call pop,sourcedir)
$(call pop,builddir)
endef

# update a variable: replaces text or appends if "from" text not found
#$(call update_var,variable_name,from_value,to_value)
update_var = $(if $(filter $(2),$($(1))),$(patsubst $2,$3,$($1)),$($(1)) $(3))

all: /tmp/lgos/bld/arch/i386/emu/hd_ext2.img
# /tmp/lgos/bld/arch/i386/boot/mbr.bin /tmp/lgos/bld/arch/i386/boot/fat.bin /tmp/lgos/bld/arch/i386/boot/ext2.bin /tmp/lgos/bld/arch/i386/loader/loader.bin  ###


include $(SOURCEDIR)/common.mk

$(call include_file,src/makefile.mk)

.PHONY: clean
clean:
	rm -rf $(BUILDDIR)
