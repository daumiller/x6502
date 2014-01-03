CC      = clang
PERL    = perl
COPTS   = -std=c99 -O3 -Wall
CLIBS   = -lpthread
SOURCES = machine/x6502.c machine/cpu.c machine/io.c machine/debug.c machine/main.c
HEADERS = machine/x6502.h machine/cpu.h machine/io.h machine/debug.h machine/functions.h machine/debug-names.h machine/opcodes.h
MAINOBJ = object/cpu.o object/debug.o object/io.o object/main.o object/x6502.o
DEVOBJ  = object/convid.o object/hdimg.o
TARGET  = x6502

all: release

machine/debug-names.h: machine/generate_debug_names.pl machine/opcodes.h
	$(PERL) machine/generate_debug_names.pl machine/opcodes.h > machine/debug-names.h

release: machine/debug-names.h $(MAINOBJ) $(DEVOBJ)
	$(CC) $(MAINOBJ) $(DEVOBJ) $(CLIBS) -o $(TARGET)

debugOpts:
	$(eval COPTS  += -DDEBUG -O0 -g )
	$(eval TARGET = $(TARGET).debug )
debug: debugOpts machine/debug-names.h $(MAINOBJ) $(DEVOBJ)
	$(CC) $(MAINOBJ) $(DEVOBJ) $(CLIBS) -o $(TARGET)

convid: object/convid.o
object/convid.o : devices/convid.c devices/convid.h machine/io.h
	$(CC) $(COPTS) -c devices/convid.c -o object/convid.o

convid: object/hdimg.o
object/hdimg.o : devices/hdimg.c devices/hdimg.h devices/ioClassStorage.h machine/io.h
	$(CC) $(COPTS) -c devices/hdimg.c -o object/hdimg.o

bootRom: boot/bootRom.s boot/boot.h
	./xa -bt0 boot/bootRom.s -o boot.rom
bootDisk: boot/bootDisk.s boot/boot.h
	./xa -bt0 boot/bootDisk.s -o hda.img

object/%.o : machine/%.c
	$(CC) $(COPTS) -c $^ -o $@

clean:
	rm -f machine/debug-names.h
	rm -f $(MAINOBJ)
	rm -f $(DEVOBJ)

veryclean: clean
	rm -f $(TARGET)
	rm -f $(TARGET).debug

remake: veryclean all
