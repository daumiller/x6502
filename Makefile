CC      = clang
PERL    = perl
COPTS   = -std=c99 -O3 -Wall
CLIBS   = -lpthread
SOURCES = machine/x6502.c machine/cpu.c machine/io.c machine/debug.c main.c
HEADERS = machine/x6502.h machine/cpu.h machine/io.h machine/debug.h \
          machine/functions.h machine/debug-names.h machine/opcodes.h
MAINOBJ = object/cpu.o object/debug.o object/io.o object/main.o object/x6502.o
DEVOBJ  = object/convid.o object/hdimg.o object/keyboard.o object/banking.o
TARGET  = x6502

#===============================================================================

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

#===============================================================================

convid: object/convid.o
object/convid.o : devices/convid.c devices/convid.h machine/io.h
	$(CC) $(COPTS) -c devices/convid.c -o object/convid.o

hdimg: object/hdimg.o
object/hdimg.o : devices/hdimg.c devices/hdimg.h devices/ioClassStorage.h machine/io.h
	$(CC) $(COPTS) -c devices/hdimg.c -o object/hdimg.o

keyboard: object/keyboard.o
object/keyboard.o : devices/keyboard.c devices/keyboard.h machine/io.h
	$(CC) $(COPTS) -c devices/keyboard.c -o object/keyboard.o

banking: object/banking.o
object/banking.o : devices/banking.c devices/banking.h machine/io.h
	$(CC) $(COPTS) -c devices/banking.c -o object/banking.o

#===============================================================================

bootRom: boot/bootRom.s boot/boot.h
	./xa -bt0 boot/bootRom.s -o boot.rom
bootImg: boot/bootImg.s boot/boot.h
	./xa -bt4864 boot/bootImg.s -o boot.img

#===============================================================================

object/main.o : main.c
	mkdir -p object
	$(CC) $(COPTS) -c $^ -o $@

object/%.o : machine/%.c
	mkdir -p object
	$(CC) $(COPTS) -c $^ -o $@

#===============================================================================

clean:
	rm -f machine/debug-names.h
	rm -f $(MAINOBJ)
	rm -f $(DEVOBJ)

veryclean: clean
	rm -f $(TARGET)
	rm -f $(TARGET).debug

remake: veryclean all
