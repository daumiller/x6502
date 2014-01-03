case ASL_AB:
    arg1 = NEXT_BYTE(m);
    r1 = mem_abs(arg1, NEXT_BYTE(m), 0);
    set_flag(m, FLAG_CARRY, m->ram[r1] & 0x80);
    m->ram[r1] = (m->ram[r1] << 1) & 0xFE;
    set_flags(m, m->ram[r1]);
    mark_dirty(m, r1);
    break;

case ASL_ABX:
    arg1 = NEXT_BYTE(m);
    r1 = mem_abs(arg1, NEXT_BYTE(m), m->x);
    set_flag(m, FLAG_CARRY, m->ram[r1] & 0x80);
    m->ram[r1] = (m->ram[r1] << 1) & 0xFE;
    set_flags(m, m->ram[r1]);
    mark_dirty(m, r1);
    break;

case ASL_ACC:
    set_flag(m, FLAG_CARRY, m->a & 0x80);
    m->a = (m->a << 1) & 0xFE;
    set_flags(m, m->a);
    break;

case ASL_ZP:
    arg1 = NEXT_BYTE(m);
    set_flag(m, FLAG_CARRY, m->ram[arg1] & 0x80);
    m->ram[arg1] = (m->ram[arg1] << 1) & 0xFE;
    set_flags(m, m->ram[arg1]);
    mark_dirty(m, arg1);
    break;

case ASL_ZPX:
    arg1 = ZP(NEXT_BYTE(m) + m->x);
    set_flag(m, FLAG_CARRY, m->ram[arg1] & 0x80);
    m->ram[arg1] = (m->ram[arg1] << 1) & 0xFE;
    set_flags(m, m->ram[arg1]);
    mark_dirty(m, arg1);
    break;

case LSR_AB:
    arg1 = NEXT_BYTE(m);
    r1 = mem_abs(arg1, NEXT_BYTE(m), 0);
    set_flag(m, FLAG_CARRY, m->ram[r1] & 0x01);
    m->ram[r1] = (m->ram[r1] >> 1) & 0x7F;
    set_flags(m, m->ram[r1]);
    mark_dirty(m, r1);
    break;

case LSR_ABX:
    arg1 = NEXT_BYTE(m);
    r1 = mem_abs(arg1, NEXT_BYTE(m), m->x);
    set_flag(m, FLAG_CARRY, m->ram[r1] & 0x01);
    m->ram[r1] = (m->ram[r1] >> 1) & 0x7F;
    set_flags(m, m->ram[r1]);
    mark_dirty(m, r1);
    break;

case LSR_ACC:
    set_flag(m, FLAG_CARRY, m->a & 0x01);
    m->a = (m->a >> 1) & 0x7F;
    set_flags(m, m->a);
    break;

case LSR_ZP:
    arg1 = NEXT_BYTE(m);
    set_flag(m, FLAG_CARRY, m->ram[arg1] & 0x01);
    m->ram[arg1] = (m->ram[arg1] >> 1) & 0x7F;
    set_flags(m, m->ram[arg1]);
    mark_dirty(m, arg1);
    break;

case LSR_ZPX:
    arg1 = ZP(NEXT_BYTE(m) + m->x);
    set_flag(m, FLAG_CARRY, m->ram[arg1] & 0x01);
    m->ram[arg1] = (m->ram[arg1] >> 1) & 0x7F;
    set_flags(m, m->ram[arg1]);
    mark_dirty(m, arg1);
    break;

case ROL_AB:
    arg1 = NEXT_BYTE(m);
    r1 = mem_abs(arg1, NEXT_BYTE(m), 0);
    t1 = m->ram[r1] & 0x80;
    m->ram[r1] = ((m->ram[r1] << 1) & 0xFE) | get_flag(m, FLAG_CARRY);
    set_flag(m, FLAG_CARRY, t1);
    set_flags(m, m->ram[r1]);
    mark_dirty(m, r1);
    break;

case ROL_ABX:
    arg1 = NEXT_BYTE(m);
    r1 = mem_abs(arg1, NEXT_BYTE(m), m->x);
    t1 = m->ram[r1] & 0x80;
    m->ram[r1] = ((m->ram[r1] << 1) & 0xFE) | get_flag(m, FLAG_CARRY);
    set_flag(m, FLAG_CARRY, t1);
    set_flags(m, m->ram[r1]);
    mark_dirty(m, r1);
    break;

case ROL_ACC:
    t1 = m->a & 0x80;
    m->a = ((m->a << 1) & 0xFE) | get_flag(m, FLAG_CARRY);
    set_flag(m, FLAG_CARRY, t1);
    set_flags(m, m->a);
    break;

case ROL_ZP:
    arg1 = NEXT_BYTE(m);
    t1 = m->ram[arg1] & 0x80;
    m->ram[arg1] = ((m->ram[arg1] << 1) & 0xFE) | get_flag(m, FLAG_CARRY);
    set_flag(m, FLAG_CARRY, t1);
    set_flags(m, m->ram[arg1]);
    mark_dirty(m, arg1);
    break;

case ROL_ZPX:
    arg1 = ZP(NEXT_BYTE(m) + m->x);
    t1 = m->ram[arg1] & 0x80;
    m->ram[arg1] = ((m->ram[arg1] << 1) & 0xFE) | get_flag(m, FLAG_CARRY);
    set_flag(m, FLAG_CARRY, t1);
    set_flags(m, m->ram[arg1]);
    mark_dirty(m, arg1);
    break;

case ROR_AB:
    arg1 = NEXT_BYTE(m);
    r1 = mem_abs(arg1, NEXT_BYTE(m), 0);
    t1 = m->ram[r1] & 0x01;
    m->ram[r1] = ((m->ram[r1] >> 1) & 0x7F) | (get_flag(m, FLAG_CARRY) << 7);
    set_flag(m, FLAG_CARRY, t1);
    set_flags(m, m->ram[r1]);
    mark_dirty(m, r1);
    break;

case ROR_ABX:
    arg1 = NEXT_BYTE(m);
    r1 = mem_abs(arg1, NEXT_BYTE(m), m->x);
    t1 = m->ram[r1] & 0x01;
    m->ram[r1] = ((m->ram[r1] >> 1) & 0x7F) | (get_flag(m, FLAG_CARRY) << 7);
    set_flag(m, FLAG_CARRY, t1);
    set_flags(m, m->ram[r1]);
    mark_dirty(m, r1);
    break;

case ROR_ACC:
    t1 = m->a & 0x01;
    m->a = ((m->a >> 1) & 0x7F) | (get_flag(m, FLAG_CARRY) << 7);
    set_flag(m, FLAG_CARRY, t1);
    set_flags(m, m->a);
    break;

case ROR_ZP:
    arg1 = NEXT_BYTE(m);
    t1 = m->ram[arg1] & 0x01;
    m->ram[arg1] = ((m->ram[arg1] >> 1) & 0x7F) | (get_flag(m, FLAG_CARRY) << 7);
    set_flag(m, FLAG_CARRY, t1);
    set_flags(m, m->ram[arg1]);
    mark_dirty(m, arg1);
    break;

case ROR_ZPX:
    arg1 = ZP(NEXT_BYTE(m) + m->x);
    t1 = m->ram[arg1] & 0x01;
    m->ram[arg1] = ((m->ram[arg1] >> 1) & 0x7F) | (get_flag(m, FLAG_CARRY) << 7);
    set_flag(m, FLAG_CARRY, t1);
    set_flags(m, m->ram[arg1]);
    mark_dirty(m, arg1);
    break;
