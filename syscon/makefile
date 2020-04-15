LINKFLAGS=$(COMMONFLAGS) --code-loc 0x8100 --data-loc 0xE000 --no-std-crt0

# Project config
INCLUDES 	:= $(wildcard *.h) ../libSysCon/libSysCon/libSysCon.h ../libSysCon/Kernel/kernel.h
INCLUDEPATH := ../libSysCon/Kernel/
LIBS	 	:= ../libSysCon/Kernel/bin/kernel.sys.lib
ASMSOURCES  := ./crt0.s 
MAKEDEPS 	:= ../libSysCon/Kernel
OUTDIR		:= ./build
BINFILE     := big80.sys
HEX2BINFLAGS := -s 8000
CLEAN		:= ./bin

# Default
all: makedeps binfile ./bin/$(BINFILE) upload done

include ../libSysCon/sdcc.mk

# Combine kernel.base.sys and kernel.fatfs.sys
./bin/$(BINFILE): $(OUTDIR)/$(BINFILE)
	@echo Combining overlays...
	@mkdir -p ./bin
	@cat ../libSysCon/Kernel/bin/kernel.sys $(OUTDIR)/$(BINFILE) > ./bin/$(BINFILE)

upload: ~/sf_downloads/big80.sys

~/sf_downloads/big80.sys: ./bin/$(BINFILE)
	@echo Uploading...
	@cp $< $@
	@cp $(INTDIR)/syscon.map ~/sf_downloads/
	@mcopy -o -i ~/sf_downloads/test.img@@1M $< ::
	@mdir -i ~/sf_downloads/test.img@@1M
	@#bet push --port:/dev/ttyACM1 bin/big80.sys
	@#bet reset --port:/dev/ttyACM1 
	@echo "Done!"
