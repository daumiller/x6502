+-------------------------------------------------------------+
|                                                             |
|                           x6502                             |
|                 a simple 6502 CPU emulator                  |
|                                                             |
+-------------------------------------------------------------+

    x6502 is an emulator for the 6502 class of processors.
    It currently supports the full instruction set of the
    6502 (plus a few extensions) and has an extremely
    rudimentary simulated I/O bus. It should be able to run
    arbitrary x6502 bytecode with ``correct'' results,
    although most binaries for common 6502 systems (Atari,
    C64, Apple II, etc) won't function as expected, since
    they expect I/O devices to be mapped into memory where
    there are currently none.

    x6502 is freely available under the original 4-clause
    BSD license, the full text of which is included in the
    LICENSE file.

Building and running x6502

    To build x6502, just run `make' in the project root. You
    will need clang and Perl installed. No libraries beyond
    POSIX libc are used. This will produce the x6502 binary.

    If you want to compile a version of x6502 that dumps
    machine state after every instruction, run `make debug'
    instead of `make'. This will also disable compiler
    optimizations.

Extensions to the 6502 instruction set

    x6502 recognizes two instructions that are not in the
    original 6502 instruction set. These are:

        DEBUG (0xFC): prints debugging information about the
                      current state of the emulator
        EXT (0xFF):   stops the emulator and exits

    To disable these extensions, compile with
    -DDISABLE_EXTENSIONS (right now, this can be done by
    adding that flag to the Makefile).

Reading the source

    x6502 was written to be easy to understand and read. A
    good place to start is `cpu.h', which defines a few
    constants used throughout the code (mostly around CPU
    flags) as well as the `cpu' struct, which is used pretty
    much everywhere.
    
    `cpu.c' is where the interesting stuff happens; this is
    the main loop of the emulator where opcodes are decoded
    as dispatched. It also handles interrupts and calls out
    to I/O handlers (via `io.c').

    The opcode handlers all use convenience functions
    defined in `functions.h', most of which are for the
    various addressing modes of the 6502 or for dealing with
    CPU flags.

    `io.c' is where the I/O bus lives; this is where we
    check to see if the emulated character device has been
    written to and where we raise an interrupt if we've
    gotten input from stdin.

    `generate_debug_names.pl' reads the `opcodes.h' header
    and generates `debug-names.h', which contains a mapping
    from opcode to a string representation of that opcode.
    It's only used when dumping CPU state, either because
    the DEBUG flag was set at compile time or because a
    DEBUG instruction was hit in the binary.

    The rest of the files are pretty boring; `main.c' is
    pretty much only responsible for loading bytecode into
    memory and parsing command line arguments and `debug.c' is
    used to provide the `dump_cpu' function, which is a
    fascinating function consisting of almost nothing but
    printfs.

TODO:
    - add more devices (memory banking, keyboard input, ...)

THANKS:
    - voltagex on Github for sending a patch to improve
      the sample_programs readme.
    - anatoly on HN for suggesting to add a bit on source
      code structure to the README.

USEFUL 6502 TOOLS:
  [xa   : 6502 assembler](http://www.floodgap.com/retrotech/xa/)
  [cc65 : 6502 C compiler](https://github.com/oliverschmidt/cc65)
