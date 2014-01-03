#include <stdio.h>
#include "x6502.h"
#include "cpu.h"
#include "io.h"
#include "debug.h"
#include "opcodes.h"
#include "functions.h"

cpu *cpuCreate()
{
  cpu *m   = bailCalloc(sizeof(cpu));
  m->sr    = FLAG_INTERRUPT;
  m->sp    = 0xFF;
  m->ram   = bailSalloc(SIZE_RAM, 0xFF);
  return m;
}

void cpuFree(cpu *m)
{
  free(m->ram);
  free(m);
}

#define NEXT_BYTE(m) (m->ram[m->pc + (pc_offset++)])

void cpuStart(cpu *m)
{
  u8 opcode, arg1, arg2, t1, s1;
  u16 r1, r2;

  // pc_offset is used to read from memory like a stream when processing
  // bytecode without modifying the pc. pc_start is the memory address of the
  // currently-executing opcode; if pc == pc_start at the end of a simulation
  // step, we add pc_offset to get the start of the next instruction. if pc !=
  // pc_start, we branched so we don't touch the pc.
  uint8_t pc_offset = 0;
  uint16_t pc_start;

  // branch_offset is an offset that will be added to the program counter
  // after we move to the next instruction
  int8_t branch_offset = 0;

  io_startup(m);

  while(true)
  {
    io_updatePorts(m);

    DUMP_DEBUG(m);
    reset_emu_flags(m);
    pc_offset = branch_offset = 0;
    pc_start  = m->pc;
    opcode    = NEXT_BYTE(m);

    switch(opcode)
    {
      case NOP : break;
#ifndef DISABLE_EXTENSIONS
      case EXT : goto end;
      case DUMP: dump_cpu(m); break;
#endif
      #include "opcode_handlers/arithmetic.c"
      #include "opcode_handlers/branch.c"
      #include "opcode_handlers/compare.c"
      #include "opcode_handlers/flags.c"
      #include "opcode_handlers/incdec.c"
      #include "opcode_handlers/jump.c"
      #include "opcode_handlers/load.c"
      #include "opcode_handlers/logical.c"
      #include "opcode_handlers/shift.c"
      #include "opcode_handlers/stack.c"
      #include "opcode_handlers/store.c"
      #include "opcode_handlers/transfer.c"
      default:
        fprintf(stderr, "ERROR: got unknown opcode %02x\n", opcode);
        goto end;
    }

    if(m->pc == pc_start)
      m->pc += pc_offset;
    m->pc += branch_offset;

    pthread_mutex_lock(&irqMutex);
    if(m->emu & EMU_DIRTY) io_handleWrite(m);
    if(m->irq && !get_flag(m, FLAG_INTERRUPT))
    {
      STACK_PUSH(m) = (m->pc & 0xFF00)>>8;
      STACK_PUSH(m) = m->pc & 0xFF;
      STACK_PUSH(m) = m->sr;
      m->irq = false;
      m->pc = mem_abs(m->ram[0xFFEE], m->ram[0xFFFF], 0);
      m->sr |= FLAG_INTERRUPT;
      io_serviceInt(m);
    }
    pthread_mutex_unlock(&irqMutex);

    m->prevop = opcode;
  }

end:
  io_cleanup(m);
}
