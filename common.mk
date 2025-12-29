# LGOS common makefile, include in each makefile under src/

# variables for path
# name         | value
# -------------|--------------------------------------------------------------
# relsourcedir | relative path of source directory to SOURCEDIR
# relbuilddir  | relative path of build directory to BUILDDIR
# sourcedir    | absolute path of actual source directory
# builddir     | absolute path of actual build directory

relsourcedir := $(patsubst $(SOURCEDIR)/%,%,$(patsubst %/,%,$(dir \
$(lastword $(filter-out $(lastword $(MAKEFILE_LIST)),\
$(MAKEFILE_LIST))))))

relbuilddir := $(patsubst %/,%,$(patsubst src/%,bld/%,$(relsourcedir)/))

sourcedir := $(abspath $(SOURCEDIR)/$(relsourcedir))

builddir := $(abspath $(BUILDDIR)/$(relbuilddir))

_target := $(patsubst $(sourcedir)/%,$(builddir)/%,$(addsuffix .o,$(basename \
$(wildcard $(addprefix $(sourcedir)/,*.c *.S)))))

ifneq ($(_target),)
$(_target) : | $(builddir)

$(builddir):
	mkdir -p $@
endif
