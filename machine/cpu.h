#ifndef CPU_HEADER
#define CPU_HEADER

#include "x6502.h"

#define SIZE_RAM   65536
#define PAGE_ZERO  0x0000
#define PAGE_STACK 0x0100
#define PAGE_IO    0x0200

#define FLAG_NEGATIVE  0x80
#define FLAG_OVERFLOW  0x40
#define FLAG_BREAK     0x10
#define FLAG_DECIMAL   0x08
#define FLAG_INTERRUPT 0x04
#define FLAG_ZERO      0x02
#define FLAG_CARRY     0x01

#define EMU_DIRTY 0x01

typedef struct {
  u16   pc;          // program counter
  u8    sp, sr, emu; // stackPointer, statusRegister, emuRegister
  u8    a, x, y;     // accumulator, x, y
  bool  irq;         // interrupt request waiting
  u8   *ram;         // memory
  u16   dirty;       // write address of last operation || -1
  u8    prevop;      // previous opcode (for debugging)
} cpu;

cpu *cpuCreate();
void cpuFree(cpu *m);
void cpuStart(cpu *m);

#endif //CPU_HEADER
