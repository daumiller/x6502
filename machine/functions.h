#ifndef FUNCTIONS_HEADER
#define FUNCTIONS_HEADER

#include "cpu.h"

#define ZP(x)         ((u8)(x))
#define STACK_PUSH(m) (m->ram[m->sp-- + PAGE_STACK])
#define STACK_POP(m)  (m->ram[++m->sp + PAGE_STACK])

static inline u16 mem_abs(u8 low, u8 high, u8 off)
  { return (u16)off + (u16)low + ((u16)high << 8); }

static inline u16 mem_indirect_index(cpu *m, u8 addr, u8 off)
  { return mem_abs(m->ram[addr], m->ram[addr+1], off); }

static inline u16 mem_indexed_indirect(cpu *m, u8 addr, u8 off)
  { return mem_abs(m->ram[addr+off], m->ram[addr+off+1], 0); }

// set arg MUST be 16 bits, not 8, so that add results can fit into set.
static inline void set_flag(cpu *m, u8 flag, u16 set) {
  if(set) m->sr |=  flag;
  else    m->sr &= ~flag;
}

static inline u8 get_flag(cpu *m, u8 flag)
  { return ((m->sr & flag) > 0); }

static inline u8 get_emu_flag(cpu *m, u8 flag)
  { return ((m->emu & flag) > 0); }

// set flags for the result of a computation. set_flags should be called on the
// result of any arithmetic operation.
static inline void set_flags(cpu *m, u8 val)
{
  set_flag(m, FLAG_ZERO, !val);
  set_flag(m, FLAG_NEGATIVE, val & 0x80);
}

static inline u8 bcd(u8 val) {
  // bcd is "binary coded decimal"; it treats the upper nibble and lower
  // nibble of a byte each as a decimal digit, so 01011000 -> 0101 1000 -> 58.
  // in other words, treat hex output as decimal output, so 0x58 is treated as
  // 58. this is dumb and adds a bunch of branching to opcode interpretation
  // that I Do Not Like.
  return 10 * (val >> 4) + (0x0F & val);
}

static inline void add(cpu *m, u16 r1) {
  // committing a cardinal sin for my sanity's sake. callers should initialize
  // r1 to the argument to the add.
  if (get_flag(m, FLAG_DECIMAL)) {
    r1 = bcd(r1) + bcd(m->a) + get_flag(m, FLAG_CARRY);
    set_flag(m, FLAG_CARRY, r1 > 99);
  } else {
    r1 += m->a + get_flag(m, FLAG_CARRY);
    set_flag(m, FLAG_CARRY, r1 & 0xFF00);
  }
  set_flag(m, FLAG_OVERFLOW, (m->a & 0x80) != (r1 & 0x80));
  set_flag(m, FLAG_ZERO, r1 == 0);
  set_flag(m, FLAG_NEGATIVE, r1 & 0x80);
  m->a = r1;
}

static inline void sub(cpu *m, u16 r1) {
  if (get_flag(m, FLAG_DECIMAL)) {
    r1 = bcd(m->a) - bcd(r1) - !get_flag(m, FLAG_CARRY);
    set_flag(m, FLAG_OVERFLOW, r1 > 99 || r1 < 0);
  } else {
    r1 = m->a - r1 - !get_flag(m, FLAG_CARRY);
    set_flag(m, FLAG_OVERFLOW, 0xFF00 & r1);
  }
  set_flag(m, FLAG_CARRY, r1);
  set_flag(m, FLAG_NEGATIVE, r1 & 0x80);
  set_flag(m, FLAG_ZERO, r1 == 0);
  m->a = r1;
}

static inline void cmp(cpu *m, u8 mem, u8 reg) {
  set_flag(m, FLAG_CARRY, reg >= mem);
  set_flag(m, FLAG_ZERO, reg == mem);
  set_flag(m, FLAG_NEGATIVE, 0x80 & (reg - mem));
}

// called at the start of processing an instruction to reset instruction-local
// emulator state
static inline void reset_emu_flags(cpu *m)
  { m->emu = 0x00; }

// mark a memory address as dirty
static inline void mark_dirty(cpu *m, u16 addr) {
  m->emu |= EMU_DIRTY;
  m->dirty = addr;
}

#endif //FUNCTIONS_HEADER
