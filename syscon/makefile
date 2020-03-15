LINKFLAGS=$(COMMONFLAGS) --code-loc 0x110 --data-loc 0xC000 --no-std-crt0

# Project config
INCLUDES 	:= $(wildcard *.h) ../libSysCon/libSysCon/libSysCon.h
INCLUDEPATH := ../libSysCon/libSysCon/ ../libSysCon/libFatFS/
LIBS	 	:= ../libSysCon/lib/libSysCon.lib ../libSysCon/lib/libFatFS.lib
ASMSOURCES  := ./crt0.s ./heap.s
MAKEDEPS 	:= ../libSysCon/libSysCon
OUTDIR		:= ./bin
YAZDFLAGS 	:= --entry:0 --entry:0x66 --entry:0x3b6
BINFILE     := big80.sys

# Default
all: makedeps binfile upload

include ../libSysCon/sdcc.mk


upload: ~/sf_downloads/big80.sys

~/sf_downloads/big80.sys: $(OUTDIR)/$(BINFILE)
	@echo Uploading...
	@cp $< $@
	@mcopy -o -i ~/sf_downloads/test.img@@1M $< ::
	@mdir -i ~/sf_downloads/test.img@@1M
	@#bet push --port:/dev/ttyACM1 bin/big80.sys
	@#bet reset --port:/dev/ttyACM1 
	@echo "Done!"
