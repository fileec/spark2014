# This Makefile is used to build gnat2why and gnatprove, and to install these
# tools.
#
# To build gnat2why, you need a working GNAT compiler and a symbolic link in
# gnat_backends/gnat_src that points to the GNAT sources.
#
# To build gnatprove, you additionnally need an installation of the gnatcoll
# library.
#
# For gnatprove to work, you also need working installations of Why3 and
# Alt-Ergo. The files build_instructions*.txt contains information on how to 
# install those.
#
# The necessary steps to correctly install gnat2why/gnatprove are
#
# 1) make
#
#    This will build gnatprove and gnat2why
#
# 2) make stdlib
#
#    This will apply gnat2why to the standard library of GNAT to obtain
#    precompiled Why files
#
# 3) make install
#
#    This will copy all the necessary files into the install/ subdirectory
#
# 4) Put the directory install/bin in your path:
#	export PATH=<path_to_hilite_repo>/install/bin:$PATH

.PHONY: clean doc gnat1why gnat2why gnatprove stdlib install install-stdlib

ADAINCLUDE=$(shell gnatls -v | grep adainclude)
GNAT_ROOT=$(shell echo $(ADAINCLUDE) | sed -e 's!\(.*\)/lib/gcc/\(.*\)!\1!')
INSTALLDIR=install
SHAREDIR=$(INSTALLDIR)/share
EXAMPLESDIR=$(SHAREDIR)/examples/gnatprove
DOCDIR=$(SHAREDIR)/doc/gnatprove
GNATPROVEDIR=$(SHAREDIR)/gnatprove
ALI_DIR=$(INSTALLDIR)/lib/gnatprove
GNATLIBDIR=$(GNATPROVEDIR)/stdlib
CONFIGDIR=$(GNATPROVEDIR)/config
THEORIESDIR=$(GNATPROVEDIR)/theories
STDLIB_TMP=stdlib_tmp

all: gnat2why gnatprove

all-nightly: gnat1why gnatprove local-stdlib install install-examples

install: install-stdlib
	mkdir -p $(CONFIGDIR)
	mkdir -p $(THEORIESDIR)
	cp release/share/gnatprove/config/*cgpr $(CONFIGDIR)
	cp release/share/gnatprove/theories/*why $(THEORIESDIR)
doc:
	$(MAKE) -C docs/ug latexpdf
	$(MAKE) -C docs/ug html
	mkdir -p $(DOCDIR)/pdf
	cp -p docs/ug/_build/latex/gnatprove_ug.pdf $(DOCDIR)/pdfD
	cp -pr docs/ug/_build/html $(DOCDIR)
	$(MAKE) -C docs/ug clean

gnat1why:
	$(MAKE) -C gnat_backends/why/xgen
	$(MAKE) -C gnat_backends/why gnat1 gnat2why

gnat2why:
	$(MAKE) -C gnat_backends/why/xgen
	$(MAKE) -C gnat_backends/why

gnatprove:
	$(MAKE) -C gnatprove

# Translating the standard library for GNATprove
# ==============================================
#
# We need two different targets to build the standard library:
#   local-stdlib  this target is used by the nightly builds
#   stdlib:       this target is used by the developers
# The reason for two different systems is the following: We want to make sure
# (especially in nightly builds) to use the "right" gnat2why, ie the local one
# in ../install/bin. We do so by using the -B switch of gnat2why, but this
# switch is only available in nightly builds.
# The target "stdlib" does not guarantee to use the correct gnat2why, but it
# works with both versions of gnat2why (nightly and developer version)

# Developers of GNATprove should always use "make stdlib", while nightly
# builds should always use "local-stdlib"

local-stdlib:
	rm -rf $(STDLIB_TMP)
	mkdir -p $(STDLIB_TMP)
	cp Makefile.libprove $(STDLIB_TMP)
	cp why/lib/_gnatprove_standard.mlw $(STDLIB_TMP)
	$(MAKE) -C $(STDLIB_TMP) -f Makefile.libprove ROOT=$(GNAT_ROOT) \
	GNAT2WHY="../install/bin/gnat2why -B ../install/bin -I $(ADAINCLUDE)"

stdlib:
	rm -rf $(STDLIB_TMP)
	mkdir -p $(STDLIB_TMP)
	cp Makefile.libprove $(STDLIB_TMP)
	cp why/lib/_gnatprove_standard.mlw $(STDLIB_TMP)
	$(MAKE) -C $(STDLIB_TMP) -f Makefile.libprove ROOT=$(GNAT_ROOT)

# "make stdlib-check" will run why on all Why files of the standard library,
# to detect problems with the translation to Why

stdlib-check:
	$(MAKE) -C $(STDLIB_TMP) -f Makefile.libprove ROOT=$(GNAT_ROOT) check -k

install-stdlib:
	mkdir -p $(ALI_DIR)
	mkdir -p $(GNATLIBDIR)
	cp $(STDLIB_TMP)/*.ali $(ALI_DIR)
	cp $(STDLIB_TMP)/*__types_vars_spec.mlw \
           $(STDLIB_TMP)/*__types_vars_body.mlw \
	   $(STDLIB_TMP)/*__subp_spec.mlw \
	   $(STDLIB_TMP)/*_standard.mlw \
	   $(GNATLIBDIR)

install-examples:
	mkdir -p $(EXAMPLESDIR)
	cp -r dist-examples/* $(EXAMPLESDIR)

clean:
	$(MAKE) -C gnat_backends/why/xgen clean
	$(MAKE) -C gnat_backends/why clean
	$(MAKE) -C gnatprove clean
	$(MAKE) -C docs/ug clean
