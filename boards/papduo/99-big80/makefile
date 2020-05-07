# Make script
TARGETBOARD = papduo
DEPPATH = ../../../shared-trs80 ../../../libSysCon/shared-syscon
OTHERSOURCEFILES = BootRom.vhd

build: build-bit

upload: upload-bit

# Make script
include ../../../fpgakit/fpgakit.mk

BOOTROMBIN = ../../../bootrom/bin/bootrom.bin

BootRom.vhd: $(BOOTROMBIN)
	node $(FPGAKIT)/tools/bin2vhdlrom/bin2vhdlrom \
		--addrWidth:15 \
		--writeable \
		$(BOOTROMBIN) \
		BootRom.vhd


capture: 
	@node $(FPGAKIT)/tools/reflector-client/logiccap \
	--port:/dev/ttyUSB0 \
	--baud:115200 \
	--sampleRate:1774000 \
	--autoview:150 \
	s_cpu_addr[16] \
	s_cpu_din[8] \
	s_cpu_dout[8] \
	s_mem_rd \
	s_mem_wr \
	s_port_rd \
	s_port_wr \
	s_cpu_wait_n \
	s_cpu_nmi_n \
	s_cpu_m1_n \
	s_hijacked


