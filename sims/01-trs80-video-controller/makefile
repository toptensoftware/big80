GHDLSIMOPTS = --stop-time=100ms
SIM=ghdl
DEPPATH=../../shared-trs80
OTHERSOURCEFILES = VRam.vhd

build: build-$(SIM)

view: view-$(SIM)

# Make script
include ../../fpgakit/fpgakit.mk

VRam.vhd: vram.txt
	node $(FPGAKIT)/tools/bin2vhdlrom/bin2vhdlrom \
		--addrWidth:10 \
		--fillbyte:32 \
		--clken \
		$< \
		$@

