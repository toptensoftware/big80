# Common Stuff
PROJECTNAME ?= $(notdir $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST)))))
XILT ?= xilt 
TOPMODULE ?= top
BUILDDIR ?= ./build
OUTDIR ?= ./build
BINFILE ?= $(OUTDIR)/$(PROJECTNAME).bin
SOURCEFILES ?= *.vhd *.ucf //fpgakit/shared/SuppressBenignWarnings.vhd
INPUTFILES ?= $(shell $(XILT) scandeps $(SOURCEFILES) --deppath://fpgakit/shared --deppath://shared-trs80 --deppath:./coregen)

# Build
$(BINFILE): $(INPUTFILES)
	@$(XILT) build \
	--projectName:$(PROJECTNAME) \
	--intDir:$(BUILDDIR) \
	--outDir:$(OUTDIR) \
	--topModule:$(TOPMODULE) \
	--messageFormat:msCompile \
	--noinfo \
	@../mimasv2-xilt.txt \
	$(INPUTFILES) 
	
# Upload
upload: $(BINFILE)
	mimasv2-prog --filename $(BINFILE)

# Clean
clean:
	@rm -rf $(BUILDDIR)
	@rm -rf $(OUTDIR)

	