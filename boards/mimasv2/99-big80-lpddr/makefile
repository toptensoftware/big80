# Make script
OUTDIR = bin
include ../mimasv2.mk

TestRom.vhd: TestRom.asm
	yaza --list TestRom.asm
	truncate -s 16384 TestRom.bin
	node ../../../fpgakit/tools/bin2vhdlrom/bin2vhdlrom TestRom.bin TestRom.vhd

capture: 
	@node ../../../fpgakit/tools/reflector-client/logiccap \
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

