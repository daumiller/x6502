case PHA:
    STACK_PUSH(m) = m->a;
    break;

case PHP:
    STACK_PUSH(m) = m->sr;
    break;

case PLA:
    m->a = STACK_POP(m);
    break;

case PLP:
    m->sr = STACK_POP(m);
    break;
