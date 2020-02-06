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
	--port:/dev/ttyACM1 \
	--baud:115200 \
	--sampleRate:1774000 \
	--autoview:150 \
	s_uart_write \
	s_uart_din[8] \
	s_port_wr \
	s_cpu_addr[16]
