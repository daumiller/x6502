case ADC_AB:
    arg1 = NEXT_BYTE(m);
    arg2 = NEXT_BYTE(m);
    add(m, m->ram[mem_abs(arg1, arg2, 0)]);
    break;

case ADC_ABX:
    arg1 = NEXT_BYTE(m);
    arg2 = NEXT_BYTE(m);
    add(m, m->ram[mem_abs(arg1, arg2, m->x)]);
    break;

case ADC_ABY:
    arg1 = NEXT_BYTE(m);
    arg2 = NEXT_BYTE(m);
    add(m, m->ram[mem_abs(arg1, arg2, m->y)]);
    break;

case ADC_IMM:
    add(m, NEXT_BYTE(m));
    break;

case ADC_INX:
    add(m, m->ram[mem_indexed_indirect(m, NEXT_BYTE(m), m->x)]);
    break;

case ADC_INY:
    add(m, m->ram[mem_indirect_index(m, NEXT_BYTE(m), m->y)]);
    break;

case ADC_ZP:
    add(m, m->ram[NEXT_BYTE(m)]);
    break;

case ADC_ZPX:
    add(m, m->ram[ZP(NEXT_BYTE(m) + m->x)]);
    break;

case SBC_AB:
    arg1 = NEXT_BYTE(m);
    arg2 = NEXT_BYTE(m);
    sub(m, m->ram[mem_abs(arg1, arg2, 0)]);
    break;

case SBC_ABX:
    arg1 = NEXT_BYTE(m);
    arg2 = NEXT_BYTE(m);
    sub(m, m->ram[mem_abs(arg1, arg2, m->x)]);
    break;

case SBC_ABY:
    arg1 = NEXT_BYTE(m);
    arg2 = NEXT_BYTE(m);
    sub(m, m->ram[mem_abs(arg1, arg2, m->y)]);
    break;

case SBC_IMM:
    sub(m, NEXT_BYTE(m));
    break;

case SBC_INX:
    sub(m, m->ram[mem_indexed_indirect(m, NEXT_BYTE(m), m->x)]);
    break;

case SBC_INY:
    sub(m, m->ram[mem_indirect_index(m, NEXT_BYTE(m), m->y)]);
    break;

case SBC_ZP:
    sub(m, m->ram[NEXT_BYTE(m)]);
    break;

case SBC_ZPX:
    sub(m, m->ram[ZP(NEXT_BYTE(m) + m->x)]);
    break;
