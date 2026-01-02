# LGOS common makefile, include in each makefile under src/

# variables for path
# name         | value
# -------------|--------------------------------------------------------------
# sourcedir    | absolute path of actual source directory
# builddir     | absolute path of actual build directory

_relsourcedir := $(patsubst $(SOURCEDIR)/%,%,$(patsubst %/,%,$(dir \
$(lastword $(filter-out $(lastword $(MAKEFILE_LIST)),\
$(MAKEFILE_LIST))))))

_relbuilddir := $(patsubst %/,%,$(patsubst src/%,bld/%,$(_relsourcedir)/))

sourcedir := $(abspath $(SOURCEDIR)/$(_relsourcedir))

builddir := $(abspath $(BUILDDIR)/$(_relbuilddir))

$(builddir)/%: sourcedir := $(sourcedir)
$(builddir)/%: builddir := $(builddir)

_target := $(patsubst $(sourcedir)/%,$(builddir)/%,$(addsuffix .o,$(basename \
$(wildcard $(addprefix $(sourcedir)/,*.c *.S)))))

ifneq ($(_target),)
$(_target) : | $(builddir)
endif

$(builddir):
	mkdir -p $@

undefine _relsourcedir
undefine _relbuilddir
undefine _target
