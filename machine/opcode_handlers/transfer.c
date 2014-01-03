case TAX:
    m->x = m->a;
    set_flags(m, m->x);
    break;

case TAY:
    m->y = m->a;
    set_flags(m, m->y);
    break;

case TSX:
    m->x = m->sp;
    set_flags(m, m->x);
    break;

case TXA:
    m->a = m->x;
    set_flags(m, m->a);
    break;

case TXS:
    m->sp = m->x;
    break;

case TYA:
    m->a = m->y;
    set_flags(m, m->a);
    break;
