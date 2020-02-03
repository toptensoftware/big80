COMMONFLAGS=-mz80 --stack-auto
CFLAGS=$(COMMONFLAGS) --std-c99 --disable-warning 85 --disable-warning 110 --disable-warning 126
LINKFLAGS=$(COMMONFLAGS) --code-loc 0x110 --data-loc 0xF400 --no-std-crt0
INTDIR=./build

SDCCDIR=/opt/sdcc
SDCC=$(SDCCDIR)/bin/sdcc
SDASZ80=$(SDCCDIR)/bin/sdasz80
HEX2BIN=../../tools/hex2bin
YAZD=yazd

PROJNAME := big80sys
SOURCES  := main.c diskio.c
INCLUDES := 
PROJOBJS := $(SOURCES:%.c=$(INTDIR)/%.rel)
OBJECTS  := $(INTDIR)/crt0.rel $(INTDIR)/ff.rel $(PROJOBJS)
LIBS	 := 


# Default
all: $(PROJNAME).bin

# Clean
clean:
	rm -rf $(INTDIR)
	rm -f $(PROJNAME).bin

# Rebuild
rebuild: clean all

# Compile
$(PROJOBJS): $(INTDIR)/%.rel : ./%.c $(INCLUDES)
	$(SDCC) $(CFLAGS) -c $< -o $@

# Compile
$(INTDIR)/ff.rel : ./ff.c ./ff.h ./diskio.h ./ffconf.h
	$(SDCC) $(CFLAGS) -c $< -o $@

# Link
$(PROJNAME).bin: $(INTDIR) $(OBJECTS) $(LIBS) 
	$(SDCC) $(LINKFLAGS) $(OBJECTS) $(LIBS) -o $(INTDIR)/$(PROJNAME).ihx
	$(HEX2BIN) -s 0000 -e bin $(INTDIR)/$(PROJNAME).ihx
	#$(YAZD) $(INTDIR)/$(PROJNAME).bin --entry:0 --lst > $(PROJNAME).lst


# Runtime start
$(INTDIR)/crt0.rel: crt0.s
	$(SDASZ80) -l -o $@ $<

# Directories
$(INTDIR):
	mkdir -p $(INTDIR)


	