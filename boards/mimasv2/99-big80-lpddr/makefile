# Make script
TARGETBOARD = mimasv2
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
	s_arb_request[2] \
	s_arb_granted[2] \
	s_sd_status[8] \
	s_op_write \
	s_op_cmd[2] \
	s_data_start \
	s_data_cycle \
	s_din[8] \
	s_dout[8] \
	s_din_b[8] \
	s_dout_b[8]


