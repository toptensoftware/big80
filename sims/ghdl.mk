SOURCEFILES ?= *.vhd
BUILDDIR ?= ./build
GHDLFLAGS ?=
XILT ?= xilt
GHDL ?= ghdl
GTKWAVE ?= gtkwave
INPUTFILES1 := $(shell $(XILT) scandeps $(SOURCEFILES) --deppath://shared --deppath://shared-trs80)
INPUTFILES ?= $(INPUTFILES1)
TOPMODULE1 := $(shell $(GHDL) -f $(INPUTFILES) | awk '/entity (.*) \*\*/ {print $$2}')
TOPMODULE ?= $(TOPMODULE1)
OBJS = $(addprefix $(BUILDDIR)/,$(notdir $(INPUTFILES:.vhd=.o)))
EXE = $(BUILDDIR)/$(TOPMODULE)
SIMOPTS ?=
GTKWAVEOPTS ?=

# If the gktwave config file doesn't exist, then on first
# run, include a command to zoom fit all the data
ifeq ($(wildcard gtkwave_config.gtkw),) 
    GTKWAVEOPTS += --rcvar 'do_initial_zoom_fit yes'
endif 

# Compile and Link
$(EXE): $(INPUTFILES)
	@mkdir -p $(BUILDDIR)
	xilt ghdl-filter $(GHDL) -a --workdir=$(BUILDDIR) $(GHDLFLAGS) $(INPUTFILES)
	xilt ghdl-filter $(GHDL) -m --workdir=$(BUILDDIR) -o $(EXE) $(TOPMODULE)
	@echo
	@echo "Finished."

# Run simulation if .vcd file is out of date
$(BUILDDIR)/out.vcd: $(EXE)
	@echo ------------ Start Simulation \($(SIMOPTS)\) ------------
	@$(EXE) --vcd=$(BUILDDIR)/out.vcd $(SIMOPTS)
	@echo ------------ End Simulation ------------

# Run
run: $(BUILDDIR)/out.vcd

# View (ie launch gtkwave)
view: run
	$(GTKWAVE) $(BUILDDIR)/out.vcd --save=gtkwave_config.gtkw $(GTKWAVEOPTS)

# Clean
clean:
	rm -rf build


