TARGETBOARD = mimasv2
DEPPATH = ../../../shared-trs80

build: build-bit

upload: upload-bit

# Make script
include ../../../fpgakit/fpgakit.mk


TestRom.vhd: TestRom.asm
	yaza TestRom.asm
	node ../../../fpgakit/tools/bin2vhdlrom/bin2vhdlrom --addrWidth:15 --writeable TestRom.bin TestRom.vhd

