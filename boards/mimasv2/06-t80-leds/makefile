# Make script
PROJECTNAME = big80
OUTDIR = bin
include ../mimasv2.mk

TestRom.vhd: TestRom.asm
	yaza TestRom.asm
	truncate -s 16384 TestRom.bin
	node ../../../fpgakit/tools/bin2vhdlrom/bin2vhdlrom TestRom.bin TestRom.vhd
