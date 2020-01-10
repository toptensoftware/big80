# Common Stuff
PROJECTNAME ?= $(notdir $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST)))))
XILT ?= xilt 
TOPMODULE ?= top
BUILDDIR ?= ./build
BINFILE ?= $(BUILDDIR)/$(PROJECTNAME).bin
SOURCEFILES ?= *.vhd *.ucf //shared/SuppressBenignWarnings.vhd
INPUTFILES ?= $(shell $(XILT) scandeps $(SOURCEFILES) --deppath://shared --deppath://shared-trs80 --deppath:./coregen)

# Build
$(BINFILE): $(INPUTFILES)
	@$(XILT) build \
	--projectName:$(PROJECTNAME) \
	--intDir:$(BUILDDIR) \
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
	rm -rf $(BUILDDIR)

	