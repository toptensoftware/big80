# Tools
ifeq ($(OS),Windows_NT)
SDCC=sdcc
SDAR=sdar
SDASZ80=sdasz80
else
SDCCDIR=/opt/sdcc
SDCC=sdcc-filter $(SDCCDIR)/bin/sdcc
SDAR=$(SDCCDIR)/bin/sdar
SDASZ80=$(SDCCDIR)/bin/sdasz80
endif
HEX2BIN=../tools/hex2bin
YAZD=yazd

# Build Flags
COMMONFLAGS=-mz80 --stack-auto
CFLAGS=$(COMMONFLAGS) --std-c99 --disable-warning 85 --disable-warning 110 --disable-warning 126
LINKFLAGS=$(COMMONFLAGS) --code-loc 0x110 --data-loc 0x7000 --no-std-crt0

# Project config
PROJNAME := $(notdir $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST)))))
INTDIR   := ./build
OUTDIR   := ./bin
OUTEXT   := bin
OUTNAME  := $(PROJNAME).$(OUTEXT)
OUTFILE  := $(OUTDIR)/big80.sys
SOURCES  := $(wildcard *.c)
INCLUDES := $(wildcard *.h) ../libSysCon/libSysCon/libSysCon.h
INCLUDEPATH := ../libSysCon/libSysCon/ ../libSysCon/libFatFS/
CRTOBJ   := ../libSysCon/lib/crt0.rel
LIBS	 := ../libSysCon/lib/libSysCon.lib ../libSysCon/lib/libFatFS.lib

# Collect all obj files, crt must be first
PROJOBJS := $(SOURCES:%.c=$(INTDIR)/%.rel) 
OBJS  	 := $(CRTOBJ) $(PROJOBJS)

# Default
all: $(INTDIR) $(OUTDIR) libSysCon $(OUTFILE)

# Compile
$(PROJOBJS): $(INTDIR)/%.rel : ./%.c $(INCLUDES)
	@echo Compiling $(notdir $<)...
	@$(SDCC) $(CFLAGS)  $(addprefix -I ,$(INCLUDEPATH)) -c $< -o $@

# Link
$(OUTFILE): $(OBJS) $(LIBS)
	@echo Linking $(notdir $@)...
	@$(SDCC) $(LINKFLAGS) $(OBJS) $(LIBS) -o $(INTDIR)/$(PROJNAME).ihx
	@$(HEX2BIN) -b -s 0000 -e $(OUTEXT) $(INTDIR)/$(PROJNAME).ihx
	#@$(YAZD) $(INTDIR)/$(PROJNAME).$(OUTEXT) --entry:0 --lst > $(PROJNAME).lst
	@mv $(INTDIR)/$(PROJNAME).$(OUTEXT) $(OUTFILE)
	cp $(OUTFILE) ~/sf_downloads/
	mcopy -o -i ~/sf_downloads/test.img@@1M $@ ::
	@echo "Done!"

.PHONY: libSysCon

# Directories
$(INTDIR):
	@mkdir -p $(INTDIR)

# Directories
$(OUTDIR):
	@mkdir -p $(OUTDIR)

libSysCon:
	@echo Making $@
	@$(MAKE) --no-print-directory -C ../libSysCon/libSysCon

# Clean
clean:
	@rm -rf $(INTDIR)
	@rm -f $(OUTFILE)

