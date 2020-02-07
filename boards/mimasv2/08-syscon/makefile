TARGETBOARD = mimasv2
DEPPATH = ../../../shared-trs80 ../../../libSysCon/shared-syscon

build: build-bit

upload: upload-bit

# Make script
include ../../../fpgakit/fpgakit.mk

BOOTROMBIN = ../../../bootrom/bin/bootrom.bin

BootRom.vhd: $(BOOTROMBIN)
	node $(FPGAKIT)/tools/bin2vhdlrom/bin2vhdlrom \
		--addrWidth:14 \
		$(BOOTROMBIN) \
 		BootRom.vhd

capture: 
	@node $(FPGAKIT)/tools/reflector-client/logiccap \
	--port:/dev/ttyUSB0 \
	--baud:115200 \
	--sampleRate:1774000 \
	--autoview:150 \
	s_cpu_port_number[3] \
	s_cpu_port_wr_pulse \
	s_cpu_port_rd \
	s_cpu_port_rd_falling_edge \
	s_cpu_din[8] \
	s_cpu_dout[8] \
	s_cpu_addr[16] \
	s_sd_op_block_number[32]
