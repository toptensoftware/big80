# Make script
TARGETBOARD = mimasv2
DEPPATH = ../../../shared-trs80

build: build-bit

upload: upload-bit

# Make script
include ../../../fpgakit/fpgakit.mk

TestRom.vhd: TestRom.asm
	yaza --list TestRom.asm
	node $(FPGAKIT)/tools/bin2vhdlrom/bin2vhdlrom --addrWidth:14 TestRom.bin TestRom.vhd

capture: 
	@node $(FPGAKIT)/tools/reflector-client/logiccap \
	--port:/dev/ttyACM1 \
	--baud:115200 \
	--sampleRate:80000000 \
	--autoview:150 \
	s_pc[16] \
	s_cpu_addr[16] \
	s_cpu_din[8] \
	s_cpu_dout[8] \
	s_cpu_mreq_n \
	s_cpu_iorq_n \
	s_cpu_rd_n \
	s_cpu_wr_n \
	mig_port_rd_data[32] \
	mig_port_wr_data[32] \
	mig_port_wr_mask[4]	
