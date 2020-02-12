LINKFLAGS=$(COMMONFLAGS) --code-loc 0x110 --data-loc 0x6000 --no-std-crt0

# Project config
INCLUDES 	:= $(wildcard *.h) ../libSysCon/libSysCon/libSysCon.h
INCLUDEPATH := ../libSysCon/libSysCon/ ../libSysCon/libFatFS/
LIBS	 	:= ../libSysCon/lib/libSysCon.lib ../libSysCon/lib/libFatFS.lib
ASMSOURCES  := ./crt0.s
MAKEDEPS 	:= ../libSysCon/libSysCon
OUTDIR		:= ./bin
YAZDFLAGS 	:= --entry:0 --entry:0x66

# Default
all: libSysCon makedeps binfile yazd

include ../libSysCon/sdcc.mk



#	#@$(YAZD) $(INTDIR)/$(PROJNAME).$(OUTEXT) --entry:0 --lst > $(PROJNAME).lst
#	@mv $(INTDIR)/$(PROJNAME).$(OUTEXT) $(OUTFILE)
#	cp $(OUTFILE) ~/sf_downloads/
#	mcopy -o -i ~/sf_downloads/test.img@@1M $@ ::
#	mdir -i ~/sf_downloads/test.img@@1M
#	@echo "Done!"


libSysCon:
	@echo Making $@
	@$(MAKE) --no-print-directory -C ../libSysCon/libSysCon

