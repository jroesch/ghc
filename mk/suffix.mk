#################################################################################
#
#			    suffix.mk
#
#		Suffix rules for fptools
#
#################################################################################

# 
# This file contain the default suffix rules for all the fptools projects.
#


# No need to define .SUFFIXES because we don't use any suffix rules
# Instead we use gmake's pattern rules exlusively

.SUFFIXES:

# This declaration tells GNU make to delete the target if it has
# changed and the command which created it exited with a non-zero exit
# code.

.DELETE_ON_ERROR:

#-----------------------------------------------------------------------------
# Haskell Suffix Rules

# The $(odir) support is for building GHC, where we need to build three
# different versions from the same sources.  See ghc/compiler/Makefile.
ifneq "$(odir)" ""
odir_ = $(odir)/
else
odir_ =
endif

# Turn off all the Haskell suffix rules if we're booting from .hc
# files.  The file bootstrap.mk contains alternative suffix rules in
# this case.
ifneq "$(BootingFromHc)" "YES"

$(odir_)%.$(way_)o : %.hs
	$(HC_PRE_OPTS)
	$(HC) $(HC_OPTS) -c $< -o $@  -ohi $(basename $@).$(way_)hi
	$(HC_POST_OPTS)

$(odir_)%.$(way_)o : %.lhs	 
	$(HC_PRE_OPTS)
	$(HC) $(HC_OPTS) -c $< -o $@  -ohi $(basename $@).$(way_)hi
	$(HC_POST_OPTS)

$(odir_)%.$(way_)hc : %.lhs	 
	$(RM) $@
	$(HC) $(HC_OPTS) -C $< -o $@

$(odir_)%.$(way_)hc : %.hs	 
	$(RM) $@
	$(HC) $(HC_OPTS) -C $< -o $@

$(odir_)%.$(way_)o : %.$(way_)hc
	$(HC_PRE_OPTS)
	$(HC) $(HC_OPTS) -c $< -o $@
	$(HC_POST_OPTS)

$(odir_)%.$(way_)o : %.hc
	$(HC_PRE_OPTS)
	$(HC) $(HC_OPTS) -c $< -o $@
	$(HC_POST_OPTS)

$(odir_)%.$(way_)s : %.$(way_)hc 
	$(HC_PRE_OPTS)
	$(HC) $(HC_OPTS) -S $< -o $@
	$(HC_POST_OPTS)

$(odir_)%.$(way_)hc : %.lhc
	@$(RM) $@
	$(UNLIT) $< $@
	@chmod 444 $@


# Here's an interesting rule!
# The .hi file depends on the .o file,
# so if the .hi file is dated earlier than the .o file (commonly the case,
# when interfaces are stable) this rule just makes sure that the .o file,
# is up to date.  Then it does nothing to generate the .hi file from the 
# .o file, because the act of making sure the .o file is up to date also
# updates the .hi file (if necessary).

%.$(way_)hi : %.$(way_)o
	@if [ ! -f $@ ] ; then \
	    echo Panic! $< exists, but $@ does not.; \
	    exit 1; \
	else exit 0 ; \
	fi							

$(odir_)%.$(way_)hi : %.$(way_)hc
	@if [ ! -f $@ ] ; then \
	    echo Panic! $< exists, but $@ does not.; \
	    exit 1; \
	else exit 0 ; \
	fi

else # BootingFromHc

# -----------------------------------------------------------------------------
# suffix rules for building a .o from a .hc file in bootstrap mode.

ifeq "$(BootingFromUnregisterisedHc)" "YES"

# without mangling

$(odir_)%.o : %.hc
	$(CC) -x c $< -o $@ -c -O $(HC_BOOT_CC_OPTS) -I.  `echo $(patsubst -monly-%-regs, -DSTOLEN_X86_REGS=%, $(filter -monly-%-regs, $($*_HC_OPTS))) | sed 's/^$$/-DSTOLEN_X86_REGS=4/'`

else

# with mangling

$(odir_)%.raw_s : %.hc
	$(CC) -x c $< -o $@ -S -O $(HC_BOOT_CC_OPTS) -I.  `echo $(patsubst -monly-%-regs, -DSTOLEN_X86_REGS=%, $(filter -monly-%-regs, $($*_HC_OPTS))) | sed 's/^$$/-DSTOLEN_X86_REGS=4/'`

$(odir_)%.s : %.raw_s
	$(GHC_MANGLER) $< $@ $(patsubst -monly-%-regs, %, $(filter -monly-%-regs, $($*_HC_OPTS)))

$(odir_)%.o : %.s
	$(CC) -c -o $@ $<

endif # not BootingFromUnregisterisedHc

endif # BootingFromHc

#-----------------------------------------------------------------------------
# Happy Suffix Rules
#
.SECONDARY: %.hs

%.hs : %.ly
	$(HAPPY) $(HAPPY_OPTS) $<

%.hs : %.y
	$(HAPPY) $(HAPPY_OPTS) $<

#-----------------------------------------------------------------------------
# Alex Suffix Rules
#

%.hs : %.x
	$(ALEX) $(ALEX_OPTS) $<

#-----------------------------------------------------------------------------
# hsc2hs Suffix Rules
#
ifneq "$(BootingFromHc)" "YES"
%_hsc.c %_hsc.h %.hs : %.hsc
	$(HSC2HS) $(HSC2HS_OPTS) $<
	@touch $(patsubst %.hsc,%_hsc.c,$<)
endif

#-----------------------------------------------------------------------------
# Lx Suffix Rules
#

%.hs : %.lx
	$(LX) $(LX_OPTS) $<

#-----------------------------------------------------------------------------
# Green-card Suffix Rules
#

.PRECIOUS: %.gc

%.hs %_stub_ffi.c %_stub_ffi.h : %.gc
	$(GREENCARD) $(GC_OPTS) $<

%.lhs : %.gc
	$(GREENCARD) $(GC_OPTS) $< -o $@

%.gc : %.pgc
	$(CPP) $(GC_CPP_OPTS) $< | perl -pe 's#\\n#\n#g' > $@

#-----------------------------------------------------------------------------
# C-related suffix rules

# UseGhcForCc is only relevant when not booting from HC files.
ifeq "$(UseGhcForCc) $(BootingFromHc)" "YES NO"

$(odir_)%.$(way_)o : %.c
	@$(RM) $@
	$(HC) $(GHC_CC_OPTS) -c $< -o $@

$(odir_)%.$(way_)o : %.$(way_)s
	@$(RM) $@
	$(HC) $(GHC_CC_OPTS) -c $< -o $@

$(odir_)%.$(way_)o : %.S
	@$(RM) $@
	$(HC) $(GHC_CC_OPTS) -c $< -o $@

$(odir_)%.$(way_)s : %.c
	@$(RM) $@
	$(HC) $(GHC_CC_OPTS) -S $< -o $@

else

$(odir_)%.$(way_)o : %.c
	@$(RM) $@
	$(CC) $(CC_OPTS) -c $< -o $@

$(odir_)%.$(way_)o : %.$(way_)s
	@$(RM) $@
	$(AS) $(AS_OPTS) -o $@ $<

$(odir_)%.$(way_)o : %.S
	@$(RM) $@
	$(CC) $(CC_OPTS) -c $< -o $@

$(odir_)%.$(way_)s : %.c
	@$(RM) $@
	$(CC) $(CC_OPTS) -S $< -o $@

endif

# stubs are automatically generated and compiled by GHC
%_stub.$(way_)o: %.o
	@:

# -----------------------------------------------------------------------------
# Flex/lex

%.c : %.flex
	@$(RM) $@
	$(FLEX) -t $(FLEX_OPTS) $< > $@
%.c : %.lex
	@$(RM) $@
	$(FLEX) -t $(FLEX_OPTS) $< > $@

#-----------------------------------------------------------------------------
# Runtest rules for calling $(HC) on a single-file Haskell program

%.runtest : %.hs
	$(TIME) $(RUNTEST) $(HC) $(RUNTEST_OPTS) $<

#-----------------------------------------------------------------------------
# DocBook XML suffix rules
#

%.html : %.xml
	$(XSLTPROC) --output $@ \
		    --stringparam html.stylesheet $(FPTOOLS_CSS) \
		    $(XSLTPROC_LABEL_OPTS) $(XSLTPROC_OPTS) \
		    $(DIR_DOCBOOK_XSL)/html/docbook.xsl $<
	cp $(FPTOOLS_CSS_ABS) .

%/index.html : %.xml
	$(RM) -rf $(dir $@)
	$(XSLTPROC) --stringparam base.dir $(dir $@) \
		    --stringparam use.id.as.filename 1 \
		    --stringparam html.stylesheet $(FPTOOLS_CSS) \
		    $(XSLTPROC_LABEL_OPTS) $(XSLTPROC_OPTS) \
		    $(DIR_DOCBOOK_XSL)/html/chunk.xsl $<
	cp $(FPTOOLS_CSS_ABS) $(dir $@)

# Note: Numeric labeling seems to be uncommon for HTML Help
%-htmlhelp/index.html : %.xml
	$(RM) -rf $(dir $@)
	$(XSLTPROC) --stringparam base.dir $(dir $@) \
		    --stringparam manifest.in.base.dir 1 \
		    --stringparam htmlhelp.chm "..\\"$(basename $<).chm \
		    $(XSLTPROC_OPTS) \
		    $(DIR_DOCBOOK_XSL)/htmlhelp/htmlhelp.xsl $<

# TODO: Detect hhc via autoconf
%.chm : %-htmlhelp/index.html
	( cd $(dir $<) && hhc htmlhelp.hhp )

%.fo : %.xml
	$(XSLTPROC) --output $@ \
		    $(XSLTPROC_LABEL_OPTS) $(XSLTPROC_OPTS) \
		    $(DIR_DOCBOOK_XSL)/fo/docbook.xsl $<

ifeq "$(FOP)" ""
ifneq "$(PDFXMLTEX)" ""
%.pdf : %.fo
	$(PDFXMLTEX) $<
	if grep "LaTeX Warning: Label(s) may have changed.Rerun to get cross-references right." $(basename $@).log > /dev/null ; then \
	  $(PDFXMLTEX) $< ; \
	  $(PDFXMLTEX) $< ; \
	fi
endif
else
%.ps : %.fo
	$(FOP) $(FOP_OPTS) -fo $< -ps $@

%.pdf : %.fo
	$(FOP) $(FOP_OPTS) -fo $< -pdf $@
endif

ifneq "$(XMLTEX)" ""
%.dvi : %.fo
	$(XMLTEX) $<
	if grep "LaTeX Warning: Label(s) may have changed.Rerun to get cross-references right." $(basename $@).log > /dev/null ; then \
	  $(XMLTEX) $< ; \
	  $(XMLTEX) $< ; \
	fi
endif

#-----------------------------------------------------------------------------
# Doc processing suffix rules
#
# ToDo: make these more robust
#
%.ps : %.dvi
	@$(RM) $@
	$(DVIPS) $< -o $@

%.tex : %.tib
	@$(RM) $*.tex $*.verb-t.tex
	$(TIB) $*.tib
	expand $*.tib-t.tex | $(VERBATIM) > $*.tex
	@$(RM) $*.tib-t.tex

%.ps : %.fig
	@$(RM) $@
	fig2dev -L ps $< $@

%.tex : %.fig
	@$(RM) $@
	fig2dev -L latex $< $@

#-----------------------------------------------------------------------------
# Literate suffix rules

%.prl : %.lprl
	@$(RM) $@
	$(UNLIT) $(UNLIT_OPTS) $< $@
	@chmod 444 $@

%.c : %.lc
	@$(RM) $@
	$(UNLIT) $(UNLIT_OPTS) $< $@
	@chmod 444 $@

%.h : %.lh
	@$(RM) $@
	$(UNLIT) $(UNLIT_OPTS) $< $@
	@chmod 444 $@

#-----------------------------------------------------------------------------
# Win32 resource files
#
# The default is to use the GNU resource compiler.
#

%.$(way_)o : %.$(way_)rc
	@$(RM) $@
	windres $< $@

#-----------------------------------------------------------------------------
# Preprocessor suffix rule

# Note use of -P option to prevent #line pragmas being left in the CPP
# output.

% : %.pp
	@$(RM) $@
	$(CPP) $(RAWCPP_FLAGS) -P $(CPP_OPTS) -x c $< > $@
