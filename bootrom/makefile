# Tools
SDCCDIR=/opt/sdcc
SDCC=$(SDCCDIR)/bin/sdcc
SDASZ80=$(SDCCDIR)/bin/sdasz80
HEX2BIN=../tools/hex2bin
YAZD=yazd

# Build Flags
COMMONFLAGS=-mz80 --stack-auto
CFLAGS=$(COMMONFLAGS) --std-c99 --disable-warning 85 --disable-warning 110 --disable-warning 126
LINKFLAGS=$(COMMONFLAGS) --code-loc 0x110 --data-loc 0xF400 --no-std-crt0

# Project config
PROJNAME := $(notdir $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST)))))
INTDIR   := ./build
OUTDIR   := ./bin
OUTEXT   := bin
OUTNAME  := $(PROJNAME).$(OUTEXT)
OUTFILE  := $(OUTDIR)/$(OUTNAME)
SOURCES  := $(wildcard *.c)
INCLUDES := $(wildcard *.h)
INCLUDEPATH := ../libSysCon/libSysCon/ ../libSysCon/libFatFSBoot
CRTOBJ   := ../libSysCon/lib/crt0.rel
LIBS	 := 

# Collect all obj files, crt must be first
PROJOBJS := $(SOURCES:%.c=$(INTDIR)/%.rel) 
OBJS  	 := $(CRTOBJ) $(PROJOBJS)

# Default
all: $(OUTFILE)

# Rebuild
rebuild: clean all

# Compile
$(PROJOBJS): $(INTDIR)/%.rel : ./%.c $(INCLUDES)
	@echo Compiling $(notdir $<)...
	$(SDCC) $(CFLAGS)  $(addprefix -I ,$(INCLUDEPATH)) -c $< -o $@

# Link
$(OUTFILE): $(INTDIR) $(OUTDIR) $(OBJS) $(LIBS) 
	@echo Linking $(notdir $@)...
	@$(SDCC) $(LINKFLAGS) $(OBJS) $(LIBS) -o $(INTDIR)/$(PROJNAME).ihx
	@$(HEX2BIN) -b -s 0000 -e $(OUTEXT) $(INTDIR)/$(PROJNAME).ihx
	@mv $(INTDIR)/$(PROJNAME).$(OUTEXT) $(OUTFILE)
	#$(YAZD) $(INTDIR)/$(PROJNAME).$(OUTEXT) --entry:0 --lst > $(PROJNAME).lst

# Directories
$(INTDIR):
	@mkdir -p $(INTDIR)

# Directories
$(OUTDIR):
	@mkdir -p $(OUTDIR)

# Clean
clean:
	@rm -rf $(INTDIR)
	@rm -f $(OUTFILE)

