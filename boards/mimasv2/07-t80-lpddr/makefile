# Make script
OUTDIR = bin
include ../mimasv2.mk

TestRom.vhd: TestRom.asm
	yaza TestRom.asm
	truncate -s 1024 TestRom.bin
	node ../../../fpgakit/tools/bin2vhdlrom/bin2vhdlrom TestRom.bin TestRom.vhd

capture: 
	@node ../../../fpgakit/tools/reflector-client/logiccap \
	--port:/dev/ttyACM1 \
	--baud:115200 \
	--sampleRate:80000000 \
	--autoview:150 \
	s_calib_done \
	s_is_ram_range \
	s_ram_write \
	s_ram_wait \
	s_ram_addr[15] \
	s_ram_din[8] \
	s_ram_dout[8] \
	s_cpu_addr[16] \
	s_cpu_din[8] \
	s_cpu_dout[8] \
	s_cpu_mreq_n \
	s_cpu_iorq_n \
	s_cpu_rd_n \
	s_cpu_wr_n \
