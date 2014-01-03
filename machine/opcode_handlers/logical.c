case AND_IMM:
    m->a &= NEXT_BYTE(m);
    set_flags(m, m->a);
    break;

case AND_ZP:
    m->a &= m->ram[NEXT_BYTE(m)];
    set_flags(m, m->a);
    break;

case AND_ZPX:
    m->a &= m->ram[ZP(NEXT_BYTE(m) + m->x)];
    set_flags(m, m->a);
    break;

case AND_AB:
    arg1 = NEXT_BYTE(m);
    arg2 = NEXT_BYTE(m);
    m->a &= m->ram[mem_abs(arg1, arg2, 0)];
    set_flags(m, m->a);
    break;

case AND_ABX:
    arg1 = NEXT_BYTE(m);
    arg2 = NEXT_BYTE(m);
    m->a &= m->ram[mem_abs(arg1, arg2, m->x)];
    set_flags(m, m->a);
    break;

case AND_ABY:
    arg1 = NEXT_BYTE(m);
    arg2 = NEXT_BYTE(m);
    m->a &= m->ram[mem_abs(arg1, arg2, m->y)];
    set_flags(m, m->a);
    break;

case AND_INX:
    m->a &= m->ram[mem_indexed_indirect(m, NEXT_BYTE(m), m->x)];
    set_flags(m, m->a);
    break;

case AND_INY:
    m->a &= m->ram[mem_indirect_index(m, NEXT_BYTE(m), m->y)];
    set_flags(m, m->a);
    break;

case EOR_IMM:
    m->a ^= NEXT_BYTE(m);
    set_flags(m, m->a);
    break;

case EOR_ZP:
    m->a ^= m->ram[NEXT_BYTE(m)];
    set_flags(m, m->a);
    break;

case EOR_ZPX:
    m->a ^= m->ram[ZP(NEXT_BYTE(m) + m->x)];
    set_flags(m, m->a);
    break;

case EOR_AB:
    arg1 = NEXT_BYTE(m);
    arg2 = NEXT_BYTE(m);
    m->a ^= m->ram[mem_abs(arg1, arg2, 0)];
    set_flags(m, m->a);
    break;

case EOR_ABX:
    arg1 = NEXT_BYTE(m);
    arg2 = NEXT_BYTE(m);
    m->a ^= m->ram[mem_abs(arg1, arg2, m->x)];
    set_flags(m, m->a);
    break;

case EOR_ABY:
    arg1 = NEXT_BYTE(m);
    arg2 = NEXT_BYTE(m);
    m->a ^= m->ram[mem_abs(arg1, arg2, m->y)];
    set_flags(m, m->a);
    break;

case EOR_INX:
    m->a ^= m->ram[mem_indexed_indirect(m, NEXT_BYTE(m), m->x)];
    set_flags(m, m->a);
    break;

case EOR_INY:
    m->a ^= m->ram[mem_indirect_index(m, NEXT_BYTE(m), m->y)];
    set_flags(m, m->a);
    break;

case ORA_IMM:
    m->a |= NEXT_BYTE(m);
    set_flags(m, m->a);
    break;

case ORA_ZP:
    m->a |= m->ram[NEXT_BYTE(m)];
    set_flags(m, m->a);
    break;

case ORA_ZPX:
    m->a |= m->ram[ZP(NEXT_BYTE(m) + m->x)];
    set_flags(m, m->a);
    break;

case ORA_AB:
    arg1 = NEXT_BYTE(m);
    arg2 = NEXT_BYTE(m);
    m->a |= m->ram[mem_abs(arg1, arg2, 0)];
    set_flags(m, m->a);
    break;

case ORA_ABX:
    arg1 = NEXT_BYTE(m);
    arg2 = NEXT_BYTE(m);
    m->a |= m->ram[mem_abs(arg1, arg2, m->x)];
    set_flags(m, m->a);
    break;

case ORA_ABY:
    arg1 = NEXT_BYTE(m);
    arg2 = NEXT_BYTE(m);
    m->a |= m->ram[mem_abs(arg1, arg2, m->y)];
    set_flags(m, m->a);
    break;

case ORA_INX:
    m->a |= m->ram[mem_indexed_indirect(m, NEXT_BYTE(m), m->x)];
    set_flags(m, m->a);
    break;

case ORA_INY:
    m->a |= m->ram[mem_indirect_index(m, NEXT_BYTE(m), m->y)];
    set_flags(m, m->a);
    break;

case BIT_AB:
    arg1 = NEXT_BYTE(m);
    arg2 = NEXT_BYTE(m);
    t1 = m->ram[mem_abs(arg1, arg2, 0)];
    set_flag(m, FLAG_ZERO, !(t1 & m->a));
    set_flag(m, FLAG_OVERFLOW, t1 & 0x40);
    set_flag(m, FLAG_NEGATIVE, t1 & 0x80);
    break;

case BIT_ZP:
    t1 = m->ram[NEXT_BYTE(m)];
    set_flag(m, FLAG_ZERO, !(t1 & m->a));
    set_flag(m, FLAG_OVERFLOW, t1 & 0x40);
    set_flag(m, FLAG_NEGATIVE, t1 & 0x80);
    break;
