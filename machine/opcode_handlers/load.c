case LDA_AB:
    arg1 = NEXT_BYTE(m);
    arg2 = NEXT_BYTE(m);
    m->a = m->ram[mem_abs(arg1, arg2, 0)];
    set_flags(m, m->a);
    break;

case LDA_ABX:
    arg1 = NEXT_BYTE(m);
    arg2 = NEXT_BYTE(m);
    m->a = m->ram[mem_abs(arg1, arg2, m->x)];
    set_flags(m, m->a);
    break;

case LDA_ABY:
    arg1 = NEXT_BYTE(m);
    arg2 = NEXT_BYTE(m);
    m->a = m->ram[mem_abs(arg1, arg2, m->y)];
    set_flags(m, m->a);
    break;

case LDA_IMM:
    m->a = NEXT_BYTE(m);
    set_flags(m, m->a);
    break;

case LDA_INX:
    m->a = m->ram[mem_indexed_indirect(m, NEXT_BYTE(m), m->x)];
    set_flags(m, m->a);
    break;

case LDA_INY:
    m->a = m->ram[mem_indirect_index(m, NEXT_BYTE(m), m->y)];
    set_flags(m, m->a);
    break;

case LDA_ZP:
    m->a = m->ram[NEXT_BYTE(m)];
    set_flags(m, m->a);
    break;

case LDA_ZPX:
    m->a = m->ram[NEXT_BYTE(m) + m->x];
    set_flags(m, m->a);
    break;

case LDX_AB:
    arg1 = NEXT_BYTE(m);
    arg2 = NEXT_BYTE(m);
    m->x = m->ram[mem_abs(arg1, arg2, 0)];
    set_flags(m, m->x);
    break;

case LDX_ABY:
    arg1 = NEXT_BYTE(m);
    arg2 = NEXT_BYTE(m);
    m->x = m->ram[mem_abs(arg1, arg2, m->y)];
    set_flags(m, m->x);
    break;

case LDX_IMM:
    m->x = NEXT_BYTE(m);
    set_flags(m, m->x);
    break;

case LDX_ZP:
    m->x = m->ram[NEXT_BYTE(m)];
    set_flags(m, m->x);
    break;

case LDX_ZPY:
    m->x = m->ram[NEXT_BYTE(m) + m->y];
    set_flags(m, m->x);
    break;

case LDY_AB:
    arg1 = NEXT_BYTE(m);
    arg2 = NEXT_BYTE(m);
    m->y = m->ram[mem_abs(arg1, arg2, 0)];
    set_flags(m, m->y);
    break;

case LDY_ABX:
    arg1 = NEXT_BYTE(m);
    arg2 = NEXT_BYTE(m);
    m->y = m->ram[mem_abs(arg1, arg2, m->x)];
    set_flags(m, m->y);
    break;

case LDY_IMM:
    m->y = NEXT_BYTE(m);
    set_flags(m, m->y);
    break;

case LDY_ZP:
    m->y = m->ram[NEXT_BYTE(m)];
    set_flags(m, m->y);
    break;

case LDY_ZPX:
    m->y = m->ram[NEXT_BYTE(m) + m->x];
    set_flags(m, m->y);
    break;
